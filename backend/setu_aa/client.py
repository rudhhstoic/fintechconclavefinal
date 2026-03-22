import requests
import os
import logging
from datetime import datetime, timedelta
from dotenv import load_dotenv
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SetuAAClient:
    BASE_URL = "https://fiu-sandbox.setu.co"

    def __init__(self):
        self.client_id = os.getenv("SETU_CLIENT_ID")
        self.client_secret = os.getenv("SETU_CLIENT_SECRET")
        self.product_instance_id = os.getenv("SETU_PRODUCT_INSTANCE_ID")
        logger.info(f"SetuAAClient init - ID: {self.client_id}, PRODUCT: {self.product_instance_id}")

    def _get_headers(self):
        return {
            "x-client-id": self.client_id,
            "x-client-secret": self.client_secret,
            "x-product-instance-id": self.product_instance_id,
            "Content-Type": "application/json"
        }

    def create_consent_request(self, user_id, mobile_number):
        url = f"{self.BASE_URL}/v2/consents"
        end_date = datetime.now()
        start_date = end_date - timedelta(days=180)
        payload = {
            "dataRange": {
                "from": start_date.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
                "to": end_date.strftime("%Y-%m-%dT%H:%M:%S.000Z")
            },
            "vua": f"{mobile_number}@onemoney",
            "consentDuration": {"unit": "MONTH", "value": 6},
            "consentTypes": ["TRANSACTIONS", "SUMMARY"],
            "fiTypes": ["DEPOSIT"],
            "fetchType": "ONETIME",
            "consentMode": "STORE",
            "purpose": {
                "code": "101",
                "text": "Personal finance management",
                "refUri": "https://api.rebit.org.in/aa/purpose/101.xml",
                "category": {"type": "string"}
            }
        }
        try:
            logger.info(f"Calling Setu: {url}")
            logger.info(f"Headers: {self._get_headers()}")
            headers = self._get_headers()
            headers["User-Agent"] = "python-requests/2.28.0"
            response = requests.post(url, json=payload, headers=headers, verify=False)
            response.raise_for_status()
            data = response.json()
            return {
                "status": "success",
                "consent_handle": data.get("id"),
                "redirect_url": data.get("url"),
                "consent_status": data.get("status")
            }
        except requests.exceptions.HTTPError as e:
            logger.error(f"HTTP error: {e.response.text}")
            return {"status": "error", "message": e.response.text}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    def get_consent_status(self, consent_handle):
        url = f"{self.BASE_URL}/v2/consents/{consent_handle}"
        try:
            response = requests.get(url, headers=self._get_headers())
            response.raise_for_status()
            data = response.json()
            return {"status": "success", "consent_status": data.get("status")}
        except requests.exceptions.HTTPError as e:
            return {"status": "error", "message": e.response.text}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    def fetch_fi_data(self, consent_handle, session_id=None):
        if not session_id:
            session_url = f"{self.BASE_URL}/v2/sessions"
            payload = {
                "consentId": consent_handle,
                "dataRange": {
                    "from": (datetime.now() - timedelta(days=180)).strftime("%Y-%m-%dT%H:%M:%S.000Z"),
                    "to": datetime.now().strftime("%Y-%m-%dT%H:%M:%S.000Z")
                }
            }
            try:
                response = requests.post(session_url, json=payload, headers=self._get_headers())
                response.raise_for_status()
                session_id = response.json().get("id")
            except requests.exceptions.HTTPError as e:
                return {"status": "error", "message": f"Session failed: {e.response.text}"}
            except Exception as e:
                return {"status": "error", "message": f"Session failed: {str(e)}"}

        data_url = f"{self.BASE_URL}/v2/sessions/{session_id}"
        try:
            response = requests.get(data_url, headers=self._get_headers())
            response.raise_for_status()
            return {"status": "success", "session_id": session_id, "raw_fi_data": response.json()}
        except requests.exceptions.HTTPError as e:
            return {"status": "error", "message": f"Fetch failed: {e.response.text}"}
        except Exception as e:
            return {"status": "error", "message": f"Fetch failed: {str(e)}"}
