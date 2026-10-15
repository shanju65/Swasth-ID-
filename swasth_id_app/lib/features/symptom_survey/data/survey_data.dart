class SurveyQuestion {
  final int id;
  final Map<String, String> questionText;
  final List<String> options; // Keys for options to be translated
  final bool allowMultiSelect;
  final Map<String, String> voiceText; // Optional specific voice text if different

  SurveyQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    this.allowMultiSelect = false,
    required this.voiceText,
  });
}

class SurveyData {
  static final List<SurveyQuestion> questions = [
    SurveyQuestion(
      id: 1,
      questionText: {
        'en': 'Select your age group',
        'hi': 'अपनी आयु वर्ग चुनें',
        'ta': 'உங்கள் வயதுப் பிரிைத் தேர்ந்தெடுக்கவும்',
      },
      voiceText: {
        'en': 'Please select your age group.',
        'hi': 'कृपया अपनी आयु वर्ग चुनें।',
        'ta': 'தயவுசெய்து உங்கள் வயதுப் பிரிவைத் தேர்ந்தெடுக்கவும்.',
      },
      options: ['0–12', '13–18', '19–30', '31–45', '46–60', '60+'],
    ),
    SurveyQuestion(
      id: 2,
      questionText: {
        'en': 'Select your gender',
        'hi': 'अपना लिंग चुनें',
        'ta': 'உங்கள் பாலினத்தைத் தேர்ந்தெடுக்கவும்',
      },
      voiceText: {
        'en': 'Please select your gender.',
        'hi': 'कृपया अपना लिंग चुनें।',
        'ta': 'தயவுசெய்து உங்கள் பாலினத்தைத் தேர்ந்தெடுக்கவும்.',
      },
      options: ['Male', 'Female', 'Prefer not to say'],
    ),
    SurveyQuestion(
      id: 3,
      questionText: {
        'en': 'Where is the pain or discomfort?',
        'hi': 'दर्द या परेशानी कहाँ है?',
        'ta': 'வலி அல்லது அசௌகரியம் எங்கே இருக்கிறது?',
      },
      voiceText: {
        'en': 'Where are you feeling pain or discomfort? You can select multiple areas.',
        'hi': 'आपको दर्द या परेशानी कहाँ महसूस हो रही है? आप एक से अधिक विकल्प चुन सकते हैं।',
        'ta': 'நீங்கள் எங்கே வலி அல்லது அசௌகரியத்தை உணர்கிறீர்கள்? நீங்கள் பல இடங்களைத் தேர்ந்தெடுக்கலாம்.',
      },
      allowMultiSelect: true,
      options: [
        'Head', 'Neck', 'Shoulders',
        'Chest', 'Stomach', 'Upper Back', 'Lower Back',
        'Arms', 'Legs', 'Knees', 'Feet',
        'Overall Body', 'No pain'
      ],
    ),
    SurveyQuestion(
      id: 4,
      questionText: {
        'en': 'General Symptoms',
        'hi': 'सामान्य लक्षण',
        'ta': 'பொதுவான அறிகுறிகள்',
      },
      voiceText: {
        'en': 'Do you have fever, fatigue, or body aches?',
        'hi': 'क्या आपको बुखार, थकान या बदन दर्द है?',
        'ta': 'உங்களுக்கு காய்ச்சல், சோர்வு அல்லது உடல் வலி உள்ளதா?',
      },
      allowMultiSelect: true,
      options: [
        'Fever',
        'Chills / Shivering',
        'Body pain',
        'Fatigue',
        'Weakness',
        'Weight loss',
        'Night sweats',
        'None'
      ],
    ),
    SurveyQuestion(
      id: 5,
      questionText: {
        'en': 'Head, Throat & Respiratory',
        'hi': 'सिर, गला और सांस',
        'ta': 'தலை, தொண்டை மற்றும் சுவாசம்',
      },
      voiceText: {
        'en': 'Any cough, cold, or throat issues?',
        'hi': 'क्या कोई खांसी, जुकाम या गले की समस्या है?',
        'ta': 'ஏதேனும் இருமல், சளி அல்லது தொண்டை பிரச்சனைகள் உள்ளதா?',
      },
      allowMultiSelect: true,
      options: [
        'Headache',
        'Cold / Cough',
        'Sore throat',
        'Runny nose',
        'Breathing difficulty',
        'Ear pain',
        'Red eyes',
        'None'
      ],
    ),
    SurveyQuestion(
      id: 6,
      questionText: {
        'en': 'Stomach & Digestion',
        'hi': 'पेट और पाचन',
        'ta': 'வயிறு மற்றும் செரிமானம்',
      },
      voiceText: {
        'en': 'Any stomach or digestive issues?',
        'hi': 'क्या पेट या पाचन संबंधी कोई समस्या है?',
        'ta': 'ஏதேனும் வயிறு அல்லது செரிமான பிரச்சனைகள் உள்ளதா?',
      },
      allowMultiSelect: true,
      options: [
        'Stomach pain',
        'Acidity / Heartburn',
        'Nausea',
        'Vomiting',
        'Diarrhea',
        'Constipation',
        'Loss of appetite',
        'None'
      ],
    ),
    SurveyQuestion(
      id: 7,
      questionText: {
        'en': 'Skin & Other Symptoms',
        'hi': 'त्वचा और अन्य लक्षण',
        'ta': 'தோல் மற்றும் பிற அறிகுறிகள்',
      },
      voiceText: {
        'en': 'Any skin issues or other problems?',
        'hi': 'क्या कोई त्वचा संबंधी या अन्य समस्या है?',
        'ta': 'ஏதேனும் தோல் பிரச்சனைகள் அல்லது பிற பிரச்சனைகள் உள்ளதா?',
      },
      allowMultiSelect: true,
      options: [
        'Skin rash',
        'Itching',
        'Boils / Lumps',
        'Swelling',
        'Joint pain',
        'Burning urine',
        'Frequent urination',
        'Dizziness',
        'None'
      ],
    ),
    SurveyQuestion(
      id: 8,
      questionText: {
        'en': 'How long have you had these symptoms?',
        'hi': 'आपको ये लक्षण कब से हैं?',
        'ta': 'இந்த அறிகுறிகள் உங்களுக்கு எவ்வளவு காலமாக உள்ளன?',
      },
      voiceText: {
        'en': 'How long have you had these symptoms?',
        'hi': 'आपको ये लक्षण कितने समय से हैं?',
        'ta': 'இந்த அறிகுறிகள் உங்களுக்கு எவ்வளவு காலமாக உள்ளன?',
      },
      options: [
        'Today',
        '1–2 days',
        '3–5 days',
        'More than 1 week',
        'More than 1 month'
      ],
    ),
    SurveyQuestion(
      id: 9,
      questionText: {
        'en': 'Rate the severity',
        'hi': 'गंभीरता का स्तर चुनें',
        'ta': 'தீவிரத்தை மதிப்பிடவும்',
      },
      voiceText: {
        'en': 'How severe are your symptoms?',
        'hi': 'आपके लक्षण कितने गंभीर हैं?',
        'ta': 'உங்கள் அறிகுறிகள் எவ்வளவு தீவிரமானவை?',
      },
      options: ['Mild', 'Moderate', 'Severe', 'Very Severe'],
    ),
    SurveyQuestion(
      id: 10,
      questionText: {
        'en': 'Do you have any of these warning signs?',
        'hi': 'क्या आपको इनमें से कोई चेतावनी संकेत है?',
        'ta': 'இவற்றில் ஏதேனும் எச்சரிக்கை அறிகுறிகள் உள்ளதா?',
      },
      voiceText: {
        'en': 'Do you have any of the following serious warning signs?',
        'hi': 'क्या आपको इनमें से कोई गंभीर लक्षण है?',
        'ta': 'பின்வரும் தீவிர எச்சரிக்கை அறிகுறிகள் ஏதேனும் உங்களிடம் உள்ளதா?',
      },
      allowMultiSelect: true,
      options: [
        'High fever',
        'Chest pain',
        'Breathing problem',
        'Continuous vomiting',
        'Severe headache',
        'None of these'
      ],
    ),
  ];

  static String getTranslation(String text, String langCode) {
    // Simple static map for option translations
    // In a real app, use a proper i18n solution
    final Map<String, Map<String, String>> translations = {
      'Male': {'hi': 'पुरुष', 'ta': 'ஆண்'},
      'Female': {'hi': 'महिला', 'ta': 'பெண்'},
      'Prefer not to say': {'hi': 'कहना नहीं चाहते', 'ta': 'சொல்ல விருப்பமில்லை'},
      
      // Pain Areas
      'Head': {'hi': 'सिर', 'ta': 'தலை'},
      'Neck': {'hi': 'गर्दन', 'ta': 'கழுத்து'},
      'Shoulders': {'hi': 'कंधे', 'ta': 'தோள்கள்'},
      'Throat': {'hi': 'गला', 'ta': 'தொண்டை'},
      'Chest': {'hi': 'छाती', 'ta': 'மார்பு'},
      'Stomach': {'hi': 'पेट', 'ta': 'வயிறு'},
      'Upper Back': {'hi': 'ऊपरी पीठ', 'ta': 'மேல் முதுகு'},
      'Lower Back': {'hi': 'निचली पीठ', 'ta': 'கீழ் முதுகு'},
      'Arms': {'hi': 'हाथ', 'ta': 'கைகள்'},
      'Legs': {'hi': 'पैर', 'ta': 'கால்கள்'},
      'Knees': {'hi': 'घुटने', 'ta': 'முழங்கால்கள்'},
      'Feet': {'hi': 'पैर के पंजे', 'ta': 'பாதங்கள்'},
      'Overall Body': {'hi': 'पूरा शरीर', 'ta': 'முழு உடல்'},
      'No pain': {'hi': 'कोई दर्द नहीं', 'ta': 'வலி இல்லை'},

      // Symptoms
      'Fever': {'hi': 'बुखार', 'ta': 'காய்ச்சல்'},
      'Chills / Shivering': {'hi': 'ठंड लगना / कांपना', 'ta': 'குளிர் / நடுக்கம்'},
      'Body pain': {'hi': 'बदन दर्द', 'ta': 'உடல் வலி'},
      'Fatigue': {'hi': 'थकान', 'ta': 'சோர்வு'},
      'Weakness': {'hi': 'कमजोरी', 'ta': 'பலவீனம்'},
      'Weight loss': {'hi': 'वजन कम होना', 'ta': 'எடை இழப்பு'},
      'Night sweats': {'hi': 'रात में पसीना', 'ta': 'இரவு வியர்வை'},

      'Headache': {'hi': 'सिरदर्द', 'ta': 'தலைவலி'},
      'Cold / Cough': {'hi': 'जुकाम / खांसी', 'ta': 'சளி / இருமல்'},
      'Sore throat': {'hi': 'गले में खराश', 'ta': 'தொண்டை வலி'},
      'Runny nose': {'hi': 'बहती नाक', 'ta': 'மூக்கு ஒழுகுதல்'},
      'Breathing difficulty': {'hi': 'सांस लेने में कठिनाई', 'ta': 'மூச்சுத் திணறல்'},
      'Ear pain': {'hi': 'कान में दर्द', 'ta': 'காது வலி'},
      'Red eyes': {'hi': 'लाल आंखें', 'ta': 'சிவப்பு கண்கள்'},

      'Stomach pain': {'hi': 'पेट दर्द', 'ta': 'வயிற்று வலி'},
      'Acidity / Heartburn': {'hi': 'एसिडिटी / जलन', 'ta': 'அமிலத்தன்மை / நெஞ்செரிச்சல்'},
      'Nausea': {'hi': 'जी मिचलाना', 'ta': 'குமட்டல்'},
      'Vomiting': {'hi': 'उल्टी', 'ta': 'வாந்தி'},
      'Diarrhea': {'hi': 'दस्त', 'ta': 'வயிற்றுப்போக்கு'},
      'Constipation': {'hi': 'कब्ज', 'ta': 'மலச்சிக்கல்'},
      'Loss of appetite': {'hi': 'भूख न लगना', 'ta': 'பசியின்மை'},

      'Skin rash': {'hi': 'त्वचा पर दाने', 'ta': 'தோல் தடிப்பு'},
      'Itching': {'hi': 'खुजली', 'ta': 'அரிப்பு'},
      'Boils / Lumps': {'hi': 'फोड़े / गांठ', 'ta': 'கொப்புளங்கள் / கட்டிகள்'},
      'Swelling': {'hi': 'सूजन', 'ta': 'வீக்கம்'},
      'Joint pain': {'hi': 'जोड़ों में दर्द', 'ta': 'மூட்டு வலி'},
      'Burning urine': {'hi': 'पेशाब में जलन', 'ta': 'சிறுநீரில் எரிச்சல்'},
      'Frequent urination': {'hi': 'बार-बार पेशाब आना', 'ta': 'அடிக்கடி சிறுநீர் கழித்தல்'},
      'Dizziness': {'hi': 'चक्कर आना', 'ta': 'தலைச்சுற்றல்'},

      'None': {'hi': 'कोई नहीं', 'ta': 'ஏதுமில்லை'},

      // Duration & Severity
      'Today': {'hi': 'आज', 'ta': 'இன்று'},
      '1–2 days': {'hi': '1–2 दिन', 'ta': '1–2 நாட்கள்'},
      '3–5 days': {'hi': '3–5 दिन', 'ta': '3–5 நாட்கள்'},
      'More than 1 week': {'hi': '1 सप्ताह से अधिक', 'ta': '1 வாரத்திற்கும் மேலாக'},
       'More than 1 month': {'hi': '1 महीने से अधिक', 'ta': '1 மாதத்திற்கும் மேலாக'},

      'Mild': {'hi': 'हल्का', 'ta': 'லேசான'},
      'Moderate': {'hi': 'मध्यम', 'ta': 'மிதமான'},
      'Severe': {'hi': 'गंभीर', 'ta': 'கடுமையான'},
      'Very Severe': {'hi': 'बहुत गंभीर', 'ta': 'மிகக் கடுமையான'},

      // Warning Signs
      'High fever': {'hi': 'तेज़ बुखार', 'ta': 'அதிக காய்ச்சல்'},
      'Chest pain': {'hi': 'छाती में दर्द', 'ta': 'மார்பு வலி'},
      'Breathing problem': {'hi': 'सांस की समस्या', 'ta': 'சுவாசப் பிரச்சனை'},
      'Continuous vomiting': {'hi': 'लगातार उल्टी', 'ta': 'தொடர் வாந்தி'},
      'Severe headache': {'hi': 'तेज़ सिरदर्द', 'ta': 'கடுமையான தலைவலி'},
      'None of these': {'hi': 'इनमें से कोई नहीं', 'ta': 'இவை எதுவும் இல்லை'},
    };

    if (langCode == 'en') return text;
    return translations[text]?[langCode] ?? text;
  }
}
