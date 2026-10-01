sealed class StartupEvent {
  const StartupEvent();
}

final class StartupRequested extends StartupEvent {
  const StartupRequested();
}
