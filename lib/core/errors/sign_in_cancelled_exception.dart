/// Thrown when the user dismisses a Google/Apple sign-in sheet rather than
/// completing it. Distinct from [AppException] because the BLoC should
/// silently return to its previous state for this case, not show an error.
class SignInCancelledException implements Exception {
  const SignInCancelledException();
}
