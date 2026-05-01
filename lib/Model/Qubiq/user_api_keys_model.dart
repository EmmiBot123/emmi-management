class UserApiKeys {
  String? neuralChat;
  String? helpBot;
  String? imageGeneration;
  String? emmiTranslate;
  String? emmiLite;
  String? blockly;
  String? pyvibe;
  String? ppt;
  String? excel;
  String? word;
  String? bucketName;

  UserApiKeys({
    this.neuralChat,
    this.helpBot,
    this.imageGeneration,
    this.emmiTranslate,
    this.emmiLite,
    this.blockly,
    this.pyvibe,
    this.ppt,
    this.excel,
    this.word,
    this.bucketName,
  });

  factory UserApiKeys.fromJson(Map<String, dynamic> json) {
    return UserApiKeys(
      neuralChat: json['neuralChat'],
      helpBot: json['helpBot'],
      imageGeneration: json['imageGeneration'],
      emmiTranslate: json['emmiTranslate'],
      emmiLite: json['emmiLite'],
      blockly: json['blockly'],
      pyvibe: json['pyvibe'],
      ppt: json['ppt'],
      excel: json['excel'],
      word: json['word'],
      bucketName: json['bucketName'],
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
      'pyvibe': pyvibe,
      'ppt': ppt,
      'excel': excel,
      'word': word,
      'bucketName': bucketName,
    };
  }

  // Map to Node.js server format
  Map<String, dynamic> toNodeJson() {
    return {
      'chat': neuralChat,
      'helpbot': helpBot,
      'image': imageGeneration,
      'audio': null, 
      'translate': emmiTranslate,
      'emmiLite': emmiLite,
      'blockly': blockly,
      'pyvibe': pyvibe,
      'ppt': ppt,
      'excel': excel,
      'word': word,
      'bucketName': bucketName,
    };
  }
}
