import os
import httpx
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel, field_validator
import ipaddress
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)

app = FastAPI()

FRITZBOX_IP = os.environ.get("FRITZBOX_IP", "192.168.178.1")
FRITZBOX_PORT = os.environ.get("FRITZBOX_PORT", "49000")
FRITZBOX_USER = os.environ.get("FRITZBOX_USER", "")
FRITZBOX_PASSWORD = os.environ.get("FRITZBOX_PASSWORD", "")
FRITZBOX_URL = f"http://{FRITZBOX_IP}:{FRITZBOX_PORT}/upnp/control/x_hostfilter"
SERVICE = "urn:dslforum-org:service:X_AVM-DE_HostFilter:1"


def validate_ip(ip: str) -> str:
    try:
        ipaddress.IPv4Address(ip)
        return ip
    except ValueError:
        raise HTTPException(status_code=400, detail=f"Invalid IP address: {ip}")


async def soap_request(action: str, body: str) -> str:
    envelope = f"""<?xml version='1.0' encoding='utf-8'?>
<s:Envelope s:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/'
            xmlns:s='http://schemas.xmlsoap.org/soap/envelope/'>
  <s:Body>{body}</s:Body>
</s:Envelope>"""

    async with httpx.AsyncClient(timeout=10) as client:
        res = await client.post(
            FRITZBOX_URL,
            content=envelope,
            headers={
                "Content-Type": 'text/xml; charset="utf-8"',
                "SoapAction": f"{SERVICE}#{action}",
            },
            auth=httpx.DigestAuth(FRITZBOX_USER, FRITZBOX_PASSWORD),
        )
        res.raise_for_status()
        return res.text


@app.get("/api/status")
async def get_status(ip: str = Query(...)):
    validate_ip(ip)
    body = f"""<u:GetWANAccessByIP xmlns:u='{SERVICE}'>
      <u:NewIPv4Address>{ip}</u:NewIPv4Address>
    </u:GetWANAccessByIP>"""

    try:
        xml = await soap_request("GetWANAccessByIP", body)
    except Exception as e:
        log.error(f"Fritz!Box error: {e}")
        raise HTTPException(status_code=502, detail="Fritz!Box unreachable")

    if "<NewDisallow>0</NewDisallow>" in xml:
        state = "on"
    elif "<NewDisallow>1</NewDisallow>" in xml:
        state = "off"
    else:
        raise HTTPException(status_code=502, detail="Unexpected Fritz!Box response")

    log.info(f"Status for {ip}: {state}")
    return {"ip": ip, "state": state}


class ToggleRequest(BaseModel):
    ip: str
    state: str

    @field_validator("state")
    @classmethod
    def validate_state(cls, v):
        if v not in ("on", "off"):
            raise ValueError("state must be 'on' or 'off'")
        return v


@app.post("/api/")
async def toggle(req: ToggleRequest):
    validate_ip(req.ip)
    disallow = "0" if req.state == "on" else "1"
    body = f"""<u:DisallowWANAccessByIP xmlns:u='{SERVICE}'>
      <u:NewIPv4Address>{req.ip}</u:NewIPv4Address>
      <u:NewDisallow>{disallow}</u:NewDisallow>
    </u:DisallowWANAccessByIP>"""

    try:
        await soap_request("DisallowWANAccessByIP", body)
    except Exception as e:
        log.error(f"Fritz!Box error: {e}")
        raise HTTPException(status_code=502, detail="Fritz!Box unreachable")

    log.info(f"Internet {req.state} for {req.ip}")
    return {"status": "success", "message": f"Internet access for {req.ip} set to {req.state}"}
