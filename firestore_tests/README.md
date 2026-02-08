# Firestore Rules Tests

This folder contains emulator-backed security-rules tests for `firestore.rules`.

## Commands

- Install dependencies:
  - `npm install`
- Run rules tests with Firestore emulator:
  - `npm run test:emulator`

## Notes

- Tests require `FIRESTORE_EMULATOR_HOST`, which is set automatically by
  `firebase emulators:exec`.
- CI runs this suite via the `Firestore Rules Tests` job in
  `.github/workflows/flutter_quality_gates.yml`.
