// Абстрактный класс для обработки аудио ввода и вывода.
abstract class AudioInterface {
  /// Запускает аудио интерфейс.
  /// Вызывается один раз перед началом разговора.
  /// `inputCallback` следует регулярно вызывать с аудио данными от пользователя.
  void start(void Function(List<int>) inputCallback);

  /// Останавливает аудио интерфейс.
  /// Вызывается один раз после окончания разговора.
  void stop();

  /// Выводит аудио пользователю.
  /// Метод должен быстро возвращаться и не блокировать поток.
  void output(List<int> audio);

  /// Прерывает любой вывод аудио.
  void interrupt();
}
