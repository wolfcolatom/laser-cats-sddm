# Security

A login screen handles passwords, so:

- The password is only ever held in the password field and, while the
  explosion plays (2.2 s), in one property; the field is emptied when you
  press Enter and the property the moment the password goes to SDDM.
  `tests/tst_login.qml` checks both.
- The theme never logs, stores or sends anything. It has no network access;
  `get-cats.sh`, run by hand, is the only part that downloads (from GIPHY).
- Authentication is entirely SDDM's and PAM's; the theme only passes the
  password on.

If you find a security problem, please report it privately through
GitHub's "Report a vulnerability" (the Security tab) rather than an issue.
