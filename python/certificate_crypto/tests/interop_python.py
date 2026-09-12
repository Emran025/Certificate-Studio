import base64
import json
import sys
from certificate_crypto import KeyPair, create_record, encode_qr_payload, sign, verify_qr_payload

def b64(value):
    return base64.urlsafe_b64encode(value).rstrip(b'=').decode()

seed = bytes(range(32))
pair = KeyPair.from_private_bytes(seed)
message = b'cross-language certificate payload'
record = create_record({'institution_id': 'interop-inst', 'project_id': 'interop-project', 'certificate_id': 'CERT-001', 'course': 'Flutter'}, message, pair.private_key)
if sys.argv[1] == 'create':
    print(json.dumps({'public_key': pair.public_record()['public_key'], 'message': b64(message), 'signature': b64(sign(message, pair.private_key)), 'record': record, 'qr_payload': encode_qr_payload(record)}, ensure_ascii=False))
elif sys.argv[1] == 'verify':
    value = json.load(sys.stdin)
    assert pair.public_record()['public_key'] == value['public_key']
    assert value['signature'] == b64(sign(message, pair.private_key))
    assert value['record'] == record
    assert verify_qr_payload(value['qr_payload'], message, pair.public_key)
    print('python verification: ok')
else:
    raise SystemExit(2)
