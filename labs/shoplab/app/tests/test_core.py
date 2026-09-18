import time

from main import make_token, password_hash, read_token, unb64, verify_password


def test_password_hash_round_trip():
    stored = password_hash("atelier-alice", b"0123456789abcdef")
    assert verify_password("atelier-alice", stored)
    assert not verify_password("wrong", stored)


def test_signed_token_round_trip():
    token = make_token(1, "alice", "user")
    assert len(token.split(".")) == 3
    payload = read_token(token)
    assert payload["sub"] == "1"
    assert payload["username"] == "alice"
    assert payload["exp"] > time.time()


def test_base64url_padding_is_restored():
    assert unb64("YQ") == b"a"
