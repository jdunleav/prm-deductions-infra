#!/bin/bash -Eeuo pipefail

# Must execute from network where msg.opentest.hscic.gov.uk (192.168.11.0/24) is reachable
# dependencies:
# * aws cli
# * jq
# * curl
# Access to ASM to get secrets from /nhs/${ENVIRONMENT}/mhs/*

ENVIRONMENT="dev" # Used to get secrets from AWS ASM
TARGET_URL="https://msg.opentest.hscic.gov.uk/smsp/pds"
FROM_IP="10.0.101.251" #TODO: get my ip

# Based on example query found at:
# https://developer.nhs.uk/apis/smsp/smsp_getNHSNumber.html
cat << EOF > getNHSNumber.xml
<?xml version="1.0" encoding="UTF-8"?><!--This example message is provided for illustrative purposes only. It has had no clinical validation. Whilst every effort has been taken to ensure that the examples are consistent with the message specification, where there are conflicts with the written message specification or schema, the specification or schema shall be considered to take precedence-->
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:itk="urn:nhs-itk:ns:201005">
	<soap:Header>
		<wsa:MessageID>B72F7785-534C-11E6-ADCA-29C651A3BE6F</wsa:MessageID>
		<wsa:Action>urn:nhs-itk:services:201005:getNHSNumber-v1-0</wsa:Action>
		<wsa:To>${TARGET_URL}</wsa:To>
		<wsa:From>
			<wsa:Address>${FROM_IP}</wsa:Address>
		</wsa:From>
		<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
			<wsu:Timestamp xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" wsu:Id="D6CD5232-14CF-11DF-9423-1F9A910D4703">
				<wsu:Created>2016-07-27T11:10:23Z</wsu:Created>
				<wsu:Expires>2020-07-27T11:20:23Z</wsu:Expires>
			</wsu:Timestamp>
			<wsse:UsernameToken>
				<wsse:Username>TKS Server test</wsse:Username>
			</wsse:UsernameToken>
		</wsse:Security>
	</soap:Header>
	<soap:Body>
		<itk:DistributionEnvelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<itk:header service="urn:nhs-itk:services:201005:getNHSNumber-v1-0" trackingid="B72F9E96-534C-11E6-ADCA-29C651A3BE6F">
				<itk:auditIdentity>
					<itk:id type="1.2.826.0.1285.0.2.0.107" uri="868000003114"/>
				</itk:auditIdentity>
				<itk:manifest count="1">
					<itk:manifestitem id="uuid_808A9678-49B2-498B-AD75-1D7A0F1262D7" mimetype="text/xml" profileid="urn:nhs-en:profile:getNHSNumberRequest-v1-0" base64="false" compressed="false" encrypted="false"/>
				</itk:manifest>
				<itk:senderAddress uri="urn:nhs-uk:addressing:ods:rhm:team1:C"/>
			</itk:header>
			<itk:payloads count="1">
				<itk:payload id="uuid_808A9678-49B2-498B-AD75-1D7A0F1262D7">
					<getNHSNumberRequest-v1-0 xmlns="urn:hl7-org:v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" moodCode="EVN" classCode="CACT">
						<id root="3E25ACE2-23F8-4A37-B446-6A37F31BF77C"/>
						<code codeSystem="2.16.840.1.113883.2.1.3.2.4.17.284" code="getNHSNumberRequest-v1-0"/>
						<queryEvent>
							<Person.DateOfBirth>
								<value value="19770705" />
								<semanticsText>Person.DateOfBirth</semanticsText>
							</Person.DateOfBirth>
							<Person.Gender>
								<value code="2" codeSystem="2.16.840.1.113883.2.1.3.2.4.16.25" />
								<semanticsText>Person.Gender</semanticsText>
							</Person.Gender>

							<Person.Name>
								<value>
									<given>LILITH</given>
									<family>LAWALI</family>
								</value>
								<semanticsText>Person.Name</semanticsText>
							</Person.Name>
							<Person.Postcode>
								<value>
									<postalCode>SK8 5HS</postalCode>
								</value>
								<semanticsText>Person.Postcode</semanticsText>
							</Person.Postcode>
						</queryEvent>
					</getNHSNumberRequest-v1-0>
				</itk:payload>
			</itk:payloads>
		</itk:DistributionEnvelope>
	</soap:Body>
</soap:Envelope>
EOF

mkdir -p secrets
chmod -c 0600 secrets

aws secretsmanager get-secret-value --secret-id "/nhs/${ENVIRONMENT}/mhs/ca-certs" | jq -r ".SecretString" > secrets/opentest.ca-bundle
aws secretsmanager get-secret-value --secret-id "/nhs/${ENVIRONMENT}/mhs/client-cert" | jq -r ".SecretString" > secrets/endpoint.crt
aws secretsmanager get-secret-value --secret-id "/nhs/${ENVIRONMENT}/mhs/client-key" | jq -r ".SecretString" > secrets/endpoint.key

HTTP_RESPONSE=$(curl --silent --write-out "HTTPSTATUS:%{http_code}" \
  --cacert secrets/opentest.ca-bundle \
  --cert secrets/endpoint.crt \
  --key secrets/endpoint.key \
  -X POST \
  -H "SOAPAction: urn:nhs-itk:services:201005:getNHSNumber-v1-0" \
  -H "content-type: text/xml" \
  -d @getNHSNumber.xml \
  ${TARGET_URL})

# extract the status code
HTTP_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
if [ ! $HTTP_STATUS -eq 200  ]; then
  echo "PDS service returned HTTP status code: $HTTP_STATUS, expected 200" >&2
  exit 2
fi
HTTP_BODY=$(echo $HTTP_RESPONSE | sed -e 's/HTTPSTATUS\:.*//g')

if [[ ! echo ${HTTP_BODY} | grep -q "LAWALI"  ]]; then
  echo "HTTP response does not contain patient data." >&2
  exit 3
fi
