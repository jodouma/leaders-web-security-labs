import unittest

from authorization_policy import may_read_profile


class AuthorizationPolicyTests(unittest.TestCase):
    def test_anonymous_is_denied(self):
        self.assertFalse(may_read_profile(None, 1))

    # Ajoutez propriétaire, tiers, admin et sujet malformé.


if __name__ == "__main__":
    unittest.main()
