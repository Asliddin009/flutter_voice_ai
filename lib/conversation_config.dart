// Класс конфигурации для разговора.
class ConversationConfig {
  Map<String, dynamic> extraBody;
  Map<String, dynamic> conversationConfigOverride;

  ConversationConfig({
    Map<String, dynamic>? extraBody,
    Map<String, dynamic>? conversationConfigOverride,
  })  : extraBody = extraBody ?? {},
        conversationConfigOverride = conversationConfigOverride ?? {};
}
