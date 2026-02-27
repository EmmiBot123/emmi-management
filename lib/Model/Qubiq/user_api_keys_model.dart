class UserApiKeys {
  String? neuralChat;
  String? helpBot;
  String? imageGeneration;
  String? emmiTranslate;
  String? emmiLite;
  String? blockly;

  UserApiKeys({
    this.neuralChat,
    this.helpBot,
    this.imageGeneration,
    this.emmiTranslate,
    this.emmiLite,
    this.blockly,
  });

  factory UserApiKeys.fromJson(Map<String, dynamic> json) {
    return UserApiKeys(
      neuralChat: json['neuralChat'],
      helpBot: json['helpBot'],
      imageGeneration: json['imageGeneration'],
      emmiTranslate: json['emmiTranslate'],
      emmiLite: json['emmiLite'],
      blockly: json['blockly'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'neuralChat': neuralChat,
      'helpBot': helpBot,
      'imageGeneration': imageGeneration,
      'emmiTranslate': emmiTranslate,
      'emmiLite': emmiLite,
      'blockly': blockly,
    };
  }

  // Map to Node.js server format
  Map<String, dynamic> toNodeJson() {
    return {
      'chat': neuralChat,
      'helpbot': helpBot,
      'image': imageGeneration,
      'audio': null, // Currently null as per user requirement/example
      'translate': emmiTranslate,
      'emmiLite': emmiLite,
      'blockly': blockly,
    };
  }
}
