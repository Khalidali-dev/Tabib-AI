import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Represents a single quick triage symptom suggestion card in a country's national language.
class QuickSymptomItem {
  final String label;
  final String sub;
  final String query;

  const QuickSymptomItem({
    required this.label,
    required this.sub,
    required this.query,
  });

  Map<String, String> toMap() => {
    'label': label,
    'sub': sub,
    'query': query,
  };
}

/// Represents localized medical emergency triage contact details and national language metadata.
class EmergencyCountryInfo {
  final String countryCode;
  final String countryName;
  final String emergencyNumber;
  final String serviceName;
  final String flagEmoji;
  final String urduServiceName;
  final String nationalLanguageName;
  final String languageCode;
  final String inputHint;
  final String welcomeMessage;
  final List<QuickSymptomItem> suggestions;

  const EmergencyCountryInfo({
    required this.countryCode,
    required this.countryName,
    required this.emergencyNumber,
    required this.serviceName,
    required this.flagEmoji,
    required this.urduServiceName,
    required this.nationalLanguageName,
    required this.languageCode,
    required this.inputHint,
    required this.welcomeMessage,
    required this.suggestions,
  });
}

/// Service managing country-aware emergency triage numbers, dialing, and national language suggestions.
class EmergencyService {
  EmergencyService._internal();
  static final EmergencyService instance = EmergencyService._internal();

  static const List<EmergencyCountryInfo> supportedCountries = [
    EmergencyCountryInfo(
      countryCode: 'PK',
      countryName: 'Pakistan',
      emergencyNumber: '1122',
      serviceName: 'Rescue 1122',
      flagEmoji: '🇵🇰',
      urduServiceName: 'ریسکیو 1122',
      nationalLanguageName: 'اردو (Urdu)',
      languageCode: 'ur',
      inputHint: 'Describe symptoms or inquire about medication...',
      welcomeMessage: '👋 **Welcome to Tabib AI Doctor**\n\n'
          'Your private, on-device clinical decision support engine operating 100% offline.\n\n'
          '• **Verified Formularies**: Dosages and limits bound deterministically from local clinical catalog.\n'
          '• **Emergency Protocol**: Pakistan Emergency Services (Rescue 1122) active.\n\n'
          'Describe your symptoms or select a clinical assessment chip below to begin.',
      suggestions: [
        QuickSymptomItem(
          label: '🤒 Headache & Fever',
          sub: 'Fever & Ache',
          query: 'Severe tension headache and fever. What is the verified safe dosage and precautions?',
        ),
        QuickSymptomItem(
          label: '🔥 Acid Reflux & GERD',
          sub: 'Acidity & GERD',
          query: 'Severe heartburn, sour stomach, and acid reflux. What medication and diet are recommended?',
        ),
        QuickSymptomItem(
          label: '🩸 Fatigue & Anemia',
          sub: 'Anemia & Iron',
          query: 'Persistent fatigue, weakness, and suspected iron deficiency anemia. What are warning signs and dietary advice?',
        ),
        QuickSymptomItem(
          label: '🤧 Allergy & Rhinitis',
          sub: 'Allergy & Rash',
          query: 'Seasonal allergic rhinitis with sneezing and runny nose. What antihistamine is safe?',
        ),
        QuickSymptomItem(
          label: '🫁 Shortness of Breath',
          sub: 'Asthma / Wheezing',
          query: 'Sudden shortness of breath and wheezing. What is the emergency inhaler protocol?',
        ),
        QuickSymptomItem(
          label: '💧 Diarrhea & Dehydration',
          sub: 'Diarrhea & ORS',
          query: 'Acute watery diarrhea and vomiting. What is the proper preparation and administration for ORS?',
        ),
        QuickSymptomItem(
          label: '💊 Sore Throat & Infection',
          sub: 'Infection Protocol',
          query: 'Severe sore throat, painful swallowing, and suspected bacterial pharyngitis. Safe antibiotic precautions?',
        ),
      ],
    ),
    EmergencyCountryInfo(
      countryCode: 'SA',
      countryName: 'Saudi Arabia',
      emergencyNumber: '997',
      serviceName: 'Red Crescent 997',
      flagEmoji: '🇸🇦',
      urduServiceName: 'ہلال احمر 997',
      nationalLanguageName: 'العربية (Arabic)',
      languageCode: 'ar',
      inputHint: 'صف الأعراض أو استشر عن الأدوية...',
      welcomeMessage: '👋 **أهلاً بك في طبيب الذكاء الاصطناعي**\n\n'
          'أعمل **دون اتصال بالإنترنت بنسبة 100%** على جهازك معتمداً على بروتوكولات طبية موثقة.\n\n'
          '• **دعم اللغات**: يمكنك استشارة الطبيب بـ **العربية** أو **الإنجليزية** بكل سهولة.\n'
          '• **خدمة الطوارئ النشطة**: **الهلال الأحمر (997)** نشط للمملكة العربية السعودية.\n\n'
          'صف أعراضك الصحية أو اختر من الاقتراحات السريعة أدناه.',
      suggestions: [
        QuickSymptomItem(
          label: '🤒 صداع وحمى',
          sub: 'Fever & Headache',
          query: 'عندي صداع شديد وحمى خفيفة. ما هو الدواء الآمن والجرعة والاحتياطات؟',
        ),
        QuickSymptomItem(
          label: '🔥 حموضة وحرقة المعدة',
          sub: 'Acidity & GERD',
          query: 'أعاني من حرقة شديدة في المعدة وارتجاع حمضي. ما هو الدواء والنظام الغذائي المناسب؟',
        ),
        QuickSymptomItem(
          label: '🩸 فقر الدم ونقص الحديد',
          sub: 'Anemia & Iron',
          query: 'أشعر بضعف عام ونقص في الحديد (فقر دم). ما هي الأعراض والعلاجات الموصى بها؟',
        ),
        QuickSymptomItem(
          label: '🤧 حساسية وعطاس',
          sub: 'Allergy & Sneezing',
          query: 'أعاني من عطاس تحسسي وحكة. ما هو مضاد الهيستامين المناسب والجرعة؟',
        ),
        QuickSymptomItem(
          label: '🫁 ضيق في التنفس',
          sub: 'Asthma / Wheezing',
          query: 'أشعر بضيق في التنفس وأزيز في الصدر. ما هو بروتوكول البخاخ والإسعاف الأولي؟',
        ),
        QuickSymptomItem(
          label: '💧 إسهال وجفاف',
          sub: 'Diarrhea & ORS',
          query: 'أعاني من إسهال مائي مستمر. ما هي طريقة تحضير محلول الجفاف ORS؟',
        ),
        QuickSymptomItem(
          label: '💊 التهاب الحلق',
          sub: 'Throat Infection',
          query: 'عندي ألم في الحلق وعدوى بكتيرية. ما هي جرعة أموکسيسيلين والتحذيرات؟',
        ),
      ],
    ),
    EmergencyCountryInfo(
      countryCode: 'AE',
      countryName: 'United Arab Emirates',
      emergencyNumber: '998',
      serviceName: 'Ambulance 998',
      flagEmoji: '🇦🇪',
      urduServiceName: 'ایمبولینس 998',
      nationalLanguageName: 'العربية (Arabic)',
      languageCode: 'ar',
      inputHint: 'صف الأعراض أو استشر عن الأدوية...',
      welcomeMessage: '👋 **أهلاً بك في طبيب الذكاء الاصطناعي**\n\n'
          'أعمل **دون اتصال بالإنترنت بنسبة 100%** على جهازك معتمداً على بروتوكولات طبية موثقة.\n\n'
          '• **دعم اللغات**: يمكنك استشارة الطبيب بـ **العربية** أو **الإنجليزية** بكل سهولة.\n'
          '• **خدمة الطوارئ النشطة**: **الإسعاف الوطني (998)** نشط لدولة الإمارات العربية المتحدة.\n\n'
          'صف أعراضك الصحية أو اختر من الاقتراحات السريعة أدناه.',
      suggestions: [
        QuickSymptomItem(
          label: '🤒 صداع وحمى',
          sub: 'Fever & Headache',
          query: 'عندي صداع شديد وحمى خفيفة. ما هو الدواء الآمن والجرعة والاحتياطات؟',
        ),
        QuickSymptomItem(
          label: '🔥 حموضة وحرقة المعدة',
          sub: 'Acidity & GERD',
          query: 'أعاني من حرقة شديدة في المعدة وارتجاع حمضي. ما هو الدواء والنظام الغذائي المناسب؟',
        ),
        QuickSymptomItem(
          label: '🩸 فقر الدم والضعف',
          sub: 'Anemia & Iron',
          query: 'أشعر بضعف عام ونقص في الحديد (فقر دم). ما هي الأعراض والعلاجات الموصى بها؟',
        ),
        QuickSymptomItem(
          label: '🤧 حساسية وعطاس',
          sub: 'Allergy & Sneezing',
          query: 'أعاني من عطاس تحسسي وحكة. ما هو مضاد الهيستامين المناسب والجرعة؟',
        ),
        QuickSymptomItem(
          label: '🫁 ضيق في التنفس',
          sub: 'Asthma / Wheezing',
          query: 'أشعر بضيق في التنفس وأزيز في الصدر. ما هو بروتوكول البخاخ والإسعاف الأولي؟',
        ),
        QuickSymptomItem(
          label: '💧 إسهال وجفاف',
          sub: 'Diarrhea & ORS',
          query: 'أعاني من إسهال مائي مستمر. ما هي طريقة تحضير محلول الجفاف ORS؟',
        ),
        QuickSymptomItem(
          label: '💊 التهاب الحلق',
          sub: 'Throat Infection',
          query: 'عندي ألم في الحلق وعدوى بكتيرية. ما هي جرعة أموکسيسيلين والتحذيرات؟',
        ),
      ],
    ),
    EmergencyCountryInfo(
      countryCode: 'DE',
      countryName: 'Germany',
      emergencyNumber: '112',
      serviceName: 'Notruf 112',
      flagEmoji: '🇩🇪',
      urduServiceName: 'یورپی ایمرجنسی 112',
      nationalLanguageName: 'Deutsch (German)',
      languageCode: 'de',
      inputHint: 'Symptome beschreiben oder Medikamente anfragen...',
      welcomeMessage: '👋 **Willkommen bei Tabib AI Doctor**\n\n'
          'Ich arbeite **100% offline** auf Ihrem Gerät, gestützt auf geprüfte pharmakologische Daten.\n\n'
          '• **Sprachunterstützung**: Sie können auf **Deutsch** oder **Englisch** schreiben.\n'
          '• **Lokaler Notruf**: **Notruf 112** für Deutschland aktiv.\n\n'
          'Beschreiben Sie Ihre Symptome oder wählen Sie einen der Vorschläge unten aus.',
      suggestions: [
        QuickSymptomItem(
          label: '🤒 Kopfschmerzen & Fieber',
          sub: 'Fever & Ache',
          query: 'Ich habe starke Kopfschmerzen und leichtes Fieber. Welche Medikamente, Dosierung und Vorsichtsmaßnahmen sind sicher?',
        ),
        QuickSymptomItem(
          label: '🔥 Sodbrennen & Reflux',
          sub: 'Acidity & GERD',
          query: 'Ich leide unter schwerem Sodbrennen und saurem Aufstoßen. Welche Medikamente und Ernährung werden empfohlen?',
        ),
        QuickSymptomItem(
          label: '🩸 Blutarmut & Eisenmangel',
          sub: 'Anemia & Iron',
          query: 'Ich fühle mich schwach und vermute Blutarmut oder Eisenmangel. Welche Symptome und Behandlungen gibt es?',
        ),
        QuickSymptomItem(
          label: '🤧 Allergien & Niesen',
          sub: 'Allergy & Rash',
          query: 'Ich habe allergisches Niesen und Hautjucken. Welches Antihistaminikum und welche Dosis wird empfohlen?',
        ),
        QuickSymptomItem(
          label: '🫁 Atemnot & Asthma',
          sub: 'Asthma / Wheezing',
          query: 'Ich habe Atemnot und pfeifende Atmung. Was ist das Notfallprotokoll für Inhalatoren?',
        ),
        QuickSymptomItem(
          label: '💧 Durchfall & Dehydrierung',
          sub: 'Diarrhea & ORS',
          query: 'Ich habe wässrigen Durchfall und Übelkeit. Was ist die richtige Zubereitung von Elektrolytlösungen (ORS)?',
        ),
        QuickSymptomItem(
          label: '💊 Halsschmerzen & Infektion',
          sub: 'Infection Protocol',
          query: 'Ich habe Halsschmerzen und Anzeichen einer bakteriellen Infektion. Was ist die Dosierung für Amoxicillin?',
        ),
      ],
    ),
    EmergencyCountryInfo(
      countryCode: 'BD',
      countryName: 'Bangladesh',
      emergencyNumber: '999',
      serviceName: 'National Emergency 999',
      flagEmoji: '🇧🇩',
      urduServiceName: 'ایمرجنسی 999',
      nationalLanguageName: 'বাংলা (Bengali)',
      languageCode: 'bn',
      inputHint: 'উপসর্গ বর্ণনা করুন বা ওষুধ সম্পর্কে জিজ্ঞাসা করুন...',
      welcomeMessage: '👋 **তবিব এআই ডক্টরে স্বাগতম**\n\n'
          'আমি আপনার ডিভাইসে **১০০% অফলাইনে** নির্ভরযোগ্য চিকিৎসা প্রোটোকলের সাথে কাজ করি।\n\n'
          '• **ভাষা সহায়তা**: আপনি **বাংলা** বা **ইংরেজিতে** প্রশ্ন করতে পারেন।\n'
          '• **জরুরি সেবা**: বাংলাদেশের জন্য **জাতীয় জরুরি সেবা (৯৯৯)** সক্রিয়।\n\n'
          'আপনার লক্ষণগুলি বর্ণনা করুন অথবা নিচের যেকোনো পরামর্শে ট্যাপ করুন।',
      suggestions: [
        QuickSymptomItem(
          label: '🤒 মাথাব্যথা ও জ্বর',
          sub: 'Fever & Ache',
          query: 'আমার তীব্র মাথাব্যথা এবং জ্বর রয়েছে। নিরাপদ ওষুধ, মাত্রা এবং সতর্কতা কী?',
        ),
        QuickSymptomItem(
          label: '🔥 বুকজ্বালা ও এসিডিটি',
          sub: 'Acidity & GERD',
          query: 'আমার বুকজ্বালা এবং টক ঢেঁকুর উঠছে। কোন ওষুধ এবং খাদ্যতালিকা উপযুক্ত?',
        ),
        QuickSymptomItem(
          label: '🩸 রক্তস্বল্পতা ও দুর্বলতা',
          sub: 'Anemia & Iron',
          query: 'আমার রক্তস্বল্পতা (অ্যানিমিয়া) এবং দুর্বলতা অনুভব হচ্ছে। এর লক্ষণ ও ওষুধ কী?',
        ),
        QuickSymptomItem(
          label: '🤧 অ্যালার্জি ও হাঁচি',
          sub: 'Allergy & Rash',
          query: 'আমার অ্যালার্জি এবং বারবার হাঁচি হচ্ছে। কোন অ্যান্টিহিস্টামিন ওষুধ খাওয়া উচিত?',
        ),
        QuickSymptomItem(
          label: '🫁 শ্বাসকষ্ট ও হাঁপানি',
          sub: 'Asthma / Wheezing',
          query: 'আমার শ্বাসকষ্ট এবং বুকে বাঁশির মতো শব্দ হচ্ছে। ইনহেলার ব্যবহারের সঠিক নিয়ম কী?',
        ),
        QuickSymptomItem(
          label: '💧 ডায়রিয়া ও ওরস্যালাইন',
          sub: 'Diarrhea & ORS',
          query: 'আমার পাতলা পায়খানা ও বমি হচ্ছে। খাওয়ার স্যালাইন (ORS) তৈরির সঠিক নিয়ম কী?',
        ),
        QuickSymptomItem(
          label: '💊 গলা ব্যথা ও ইনফেকশন',
          sub: 'Infection Protocol',
          query: 'আমার গলায় তীব্র ব্যথা এবং ইনফেকশন। অ্যামোক্সিসিলিন (Amoxicillin) এর সঠিক মাত্রা কী?',
        ),
      ],
    ),
    EmergencyCountryInfo(
      countryCode: 'IN',
      countryName: 'India',
      emergencyNumber: '112',
      serviceName: 'National Emergency 112',
      flagEmoji: '🇮🇳',
      urduServiceName: 'قومی ایمرجنسی 112',
      nationalLanguageName: 'हिन्दी (Hindi)',
      languageCode: 'hi',
      inputHint: 'लक्षण बताएं या दवा के बारे में पूछें...',
      welcomeMessage: '👋 **तबीब एआई डॉक्टर में आपका स्वागत है**\n\n'
          'मैं आपके डिवाइस पर **100% ऑफलाइन** काम करता हूँ और प्रमाणित चिकित्सीय जानकारी प्रदान करता हूँ।\n\n'
          '• **भाषा समर्थन**: आप **हिन्दी** या **अंग्रेजी** में बात कर सकते हैं।\n'
          '• **आपातकालीन सेवा**: भारत के लिए **राष्ट्रीय आपातकालीन सेवा (112)** सक्रिय है।\n\n'
          'अपने लक्षण बताएं یا نیچے دیے گئے تجاویز میں سے کسی پر ٹیپ کریں۔',
      suggestions: [
        QuickSymptomItem(
          label: '🤒 सिरदर्द और बुखार',
          sub: 'Fever & Ache',
          query: 'मुझे तेज सिरदर्द और बुखार है। सुरक्षित दवा, खुराक और सावधानियां क्या हैं?',
        ),
        QuickSymptomItem(
          label: '🔥 सीने में जलन और एसिडिटी',
          sub: 'Acidity & GERD',
          query: 'सीने में तेज जलन, खट्टी डकारें और एसिडिटी है। कौन सी दवा और परहेज सही है?',
        ),
        QuickSymptomItem(
          label: '🩸 खून की कमी और कमजोरी',
          sub: 'Anemia & Iron',
          query: 'मुझे खून की कमी (एनीमिया) और कमजोरी महसूस हो रही है। इसके लक्षण, दवा और आहार क्या हैं?',
        ),
        QuickSymptomItem(
          label: '🤧 एलर्जी और छींकें',
          sub: 'Allergy & Rash',
          query: 'एलर्जी, खुجلی اور چھینکیں آ رہی ہیں۔ کون سی اینٹی الرجی دوا لینی چاہیے؟',
        ),
        QuickSymptomItem(
          label: '🫁 सांस लेने में तकलीफ',
          sub: 'Asthma / Wheezing',
          query: 'सांस लेने में कठिनाई और सीने में सीटी जैसी आवाज है। सही इनहेलर प्रोटोकॉल क्या है?',
        ),
        QuickSymptomItem(
          label: '💧 दस्त और उल्टी',
          sub: 'Diarrhea & ORS',
          query: 'पतले दस्त और उल्टी की समस्या है। ओआरएस (ORS) बनाने और लेने का सही तरीका क्या है?',
        ),
        QuickSymptomItem(
          label: '💊 गले में दर्द और संक्रमण',
          sub: 'Infection Protocol',
          query: 'गले में खराश और बैक्टीरियल इन्फेक्शन है। अमोक्सिसिलिन की सही खुराक क्या है?',
        ),
      ],
    ),
    EmergencyCountryInfo(
      countryCode: 'US',
      countryName: 'United States',
      emergencyNumber: '911',
      serviceName: 'Emergency 911',
      flagEmoji: '🇺🇸',
      urduServiceName: 'ایمرجنسی 911',
      nationalLanguageName: 'English',
      languageCode: 'en',
      inputHint: 'Describe symptoms or ask about medications...',
      welcomeMessage: '👋 **Welcome to Tabib AI Doctor**\n\n'
          'I operate **100% offline** on your device, backed by verified pharmacological data.\n\n'
          '• **Multilingual Support**: You can consult in **English**, **Urdu**, or your preferred language.\n'
          '• **Local Emergency Active**: **Emergency 911 (911)** for United States.\n\n'
          'Describe your symptoms, or tap any quick suggestion chip below.',
      suggestions: [
        QuickSymptomItem(
          label: '🤒 Headache & Fever',
          sub: 'Fever & Ache',
          query: 'I have a severe headache and mild fever. What is the safe medication, dosage and precautions?',
        ),
        QuickSymptomItem(
          label: '🔥 Acid Reflux & GERD',
          sub: 'Acidity & GERD',
          query: 'I have severe acid reflux, heartburn and sour burps. What medication and diet are recommended?',
        ),
        QuickSymptomItem(
          label: '🩸 Anemia & Fatigue',
          sub: 'Blood Deficiency',
          query: 'I feel general weakness and suspect blood deficiency or anemia. What are key symptoms, medications and dietary sources?',
        ),
        QuickSymptomItem(
          label: '🤧 Allergies & Cold',
          sub: 'Allergy & Rash',
          query: 'I have allergic sneezing, runny nose and skin itching. What antihistamine and dosage is recommended?',
        ),
        QuickSymptomItem(
          label: '🫁 Shortness of Breath',
          sub: 'Asthma / Wheezing',
          query: 'I am experiencing wheezing and shortness of breath. What is the emergency inhaler protocol?',
        ),
        QuickSymptomItem(
          label: '💧 Diarrhea & Dehydration',
          sub: 'Diarrhea & ORS',
          query: 'I have watery diarrhea and nausea. What is the correct ORS preparation and hydration protocol?',
        ),
        QuickSymptomItem(
          label: '💊 Sore Throat & Infection',
          sub: 'Infection Protocol',
          query: 'I have throat pain and bacterial infection symptoms. What is the dosage and allergy warnings for Amoxicillin?',
        ),
      ],
    ),
    EmergencyCountryInfo(
      countryCode: 'GB',
      countryName: 'United Kingdom',
      emergencyNumber: '999',
      serviceName: 'NHS / Emergency 999',
      flagEmoji: '🇬🇧',
      urduServiceName: 'ایمرجنسی 999',
      nationalLanguageName: 'English',
      languageCode: 'en',
      inputHint: 'Describe symptoms or ask about medications...',
      welcomeMessage: '👋 **Welcome to Tabib AI Doctor**\n\n'
          'I operate **100% offline** on your device, backed by verified pharmacological data.\n\n'
          '• **Multilingual Support**: You can consult in **English**, **Urdu**, or your preferred language.\n'
          '• **Local Emergency Active**: **NHS / Emergency 999 (999)** for United Kingdom.\n\n'
          'Describe your symptoms, or tap any quick suggestion chip below.',
      suggestions: [
        QuickSymptomItem(
          label: '🤒 Headache & Fever',
          sub: 'Fever & Ache',
          query: 'I have a severe headache and mild fever. What is the safe medication, dosage and precautions?',
        ),
        QuickSymptomItem(
          label: '🔥 Acid Reflux & GERD',
          sub: 'Acidity & GERD',
          query: 'I have severe acid reflux, heartburn and sour burps. What medication and diet are recommended?',
        ),
        QuickSymptomItem(
          label: '🩸 Anemia & Fatigue',
          sub: 'Blood Deficiency',
          query: 'I feel general weakness and suspect blood deficiency or anemia. What are key symptoms, medications and dietary sources?',
        ),
        QuickSymptomItem(
          label: '🤧 Allergies & Cold',
          sub: 'Allergy & Rash',
          query: 'I have allergic sneezing, runny nose and skin itching. What antihistamine and dosage is recommended?',
        ),
        QuickSymptomItem(
          label: '🫁 Shortness of Breath',
          sub: 'Asthma / Wheezing',
          query: 'I am experiencing wheezing and shortness of breath. What is the emergency inhaler protocol?',
        ),
        QuickSymptomItem(
          label: '💧 Diarrhea & Dehydration',
          sub: 'Diarrhea & ORS',
          query: 'I have watery diarrhea and nausea. What is the correct ORS preparation and hydration protocol?',
        ),
        QuickSymptomItem(
          label: '💊 Sore Throat & Infection',
          sub: 'Infection Protocol',
          query: 'I have throat pain and bacterial infection symptoms. What is the dosage and allergy warnings for Amoxicillin?',
        ),
      ],
    ),
    EmergencyCountryInfo(
      countryCode: 'CA',
      countryName: 'Canada',
      emergencyNumber: '911',
      serviceName: 'Emergency 911',
      flagEmoji: '🇨🇦',
      urduServiceName: 'ایمرجنسی 911',
      nationalLanguageName: 'English',
      languageCode: 'en',
      inputHint: 'Describe symptoms or ask about medications...',
      welcomeMessage: '👋 **Welcome to Tabib AI Doctor**\n\n'
          'I operate **100% offline** on your device, backed by verified pharmacological data.\n\n'
          '• **Multilingual Support**: You can consult in **English**, **French**, or **Urdu**.\n'
          '• **Local Emergency Active**: **Emergency 911 (911)** for Canada.\n\n'
          'Describe your symptoms, or tap any quick suggestion chip below.',
      suggestions: [
        QuickSymptomItem(
          label: '🤒 Headache & Fever',
          sub: 'Fever & Ache',
          query: 'I have a severe headache and mild fever. What is the safe medication, dosage and precautions?',
        ),
        QuickSymptomItem(
          label: '🔥 Acid Reflux & GERD',
          sub: 'Acidity & GERD',
          query: 'I have severe acid reflux, heartburn and sour burps. What medication and diet are recommended?',
        ),
        QuickSymptomItem(
          label: '🩸 Anemia & Fatigue',
          sub: 'Blood Deficiency',
          query: 'I feel general weakness and suspect blood deficiency or anemia. What are key symptoms, medications and dietary sources?',
        ),
        QuickSymptomItem(
          label: '🤧 Allergies & Cold',
          sub: 'Allergy & Rash',
          query: 'I have allergic sneezing, runny nose and skin itching. What antihistamine and dosage is recommended?',
        ),
        QuickSymptomItem(
          label: '🫁 Shortness of Breath',
          sub: 'Asthma / Wheezing',
          query: 'I am experiencing wheezing and shortness of breath. What is the emergency inhaler protocol?',
        ),
        QuickSymptomItem(
          label: '💧 Diarrhea & Dehydration',
          sub: 'Diarrhea & ORS',
          query: 'I have watery diarrhea and nausea. What is the correct ORS preparation and hydration protocol?',
        ),
        QuickSymptomItem(
          label: '💊 Sore Throat & Infection',
          sub: 'Infection Protocol',
          query: 'I have throat pain and bacterial infection symptoms. What is the dosage and allergy warnings for Amoxicillin?',
        ),
      ],
    ),
    EmergencyCountryInfo(
      countryCode: 'AU',
      countryName: 'Australia',
      emergencyNumber: '000',
      serviceName: 'Emergency 000',
      flagEmoji: '🇦🇺',
      urduServiceName: 'ایمرجنسی 000',
      nationalLanguageName: 'English',
      languageCode: 'en',
      inputHint: 'Describe symptoms or ask about medications...',
      welcomeMessage: '👋 **Welcome to Tabib AI Doctor**\n\n'
          'I operate **100% offline** on your device, backed by verified pharmacological data.\n\n'
          '• **Multilingual Support**: You can consult in **English**, **Urdu**, or your preferred language.\n'
          '• **Local Emergency Active**: **Emergency 000 (000)** for Australia.\n\n'
          'Describe your symptoms, or tap any quick suggestion chip below.',
      suggestions: [
        QuickSymptomItem(
          label: '🤒 Headache & Fever',
          sub: 'Fever & Ache',
          query: 'I have a severe headache and mild fever. What is the safe medication, dosage and precautions?',
        ),
        QuickSymptomItem(
          label: '🔥 Acid Reflux & GERD',
          sub: 'Acidity & GERD',
          query: 'I have severe acid reflux, heartburn and sour burps. What medication and diet are recommended?',
        ),
        QuickSymptomItem(
          label: '🩸 Anemia & Fatigue',
          sub: 'Blood Deficiency',
          query: 'I feel general weakness and suspect blood deficiency or anemia. What are key symptoms, medications and dietary sources?',
        ),
        QuickSymptomItem(
          label: '🤧 Allergies & Cold',
          sub: 'Allergy & Rash',
          query: 'I have allergic sneezing, runny nose and skin itching. What antihistamine and dosage is recommended?',
        ),
        QuickSymptomItem(
          label: '🫁 Shortness of Breath',
          sub: 'Asthma / Wheezing',
          query: 'I am experiencing wheezing and shortness of breath. What is the emergency inhaler protocol?',
        ),
        QuickSymptomItem(
          label: '💧 Diarrhea & Dehydration',
          sub: 'Diarrhea & ORS',
          query: 'I have watery diarrhea and nausea. What is the correct ORS preparation and hydration protocol?',
        ),
        QuickSymptomItem(
          label: '💊 Sore Throat & Infection',
          sub: 'Infection Protocol',
          query: 'I have throat pain and bacterial infection symptoms. What is the dosage and allergy warnings for Amoxicillin?',
        ),
      ],
    ),
  ];

  EmergencyCountryInfo? _currentCountry;

  EmergencyCountryInfo get currentCountry {
    _currentCountry ??= detectCurrentCountry();
    return _currentCountry!;
  }

  set currentCountry(EmergencyCountryInfo country) {
    _currentCountry = country;
  }

  /// Automatically detects current country from timezone and platform locale.
  /// Prioritizes Pakistan (PK 1122) as the default primary country.
  EmergencyCountryInfo detectCurrentCountry() {
    try {
      final now = DateTime.now();
      final offsetMinutes = now.timeZoneOffset.inMinutes;
      final tzName = now.timeZoneName.toUpperCase();

      // 1. Timezone offset & name checks (Fastest & accurate)
      if (offsetMinutes == 300 || tzName.contains('PKT') || tzName.contains('KARACHI')) {
        // Pakistan Standard Time (PKT, UTC+5)
        return supportedCountries.firstWhere((c) => c.countryCode == 'PK');
      } else if (offsetMinutes == 330 || tzName.contains('IST') || tzName.contains('KOLKATA')) {
        // Indian Standard Time (IST, UTC+5:30)
        return supportedCountries.firstWhere((c) => c.countryCode == 'IN');
      } else if (offsetMinutes == 180 || tzName.contains('AST') || tzName.contains('RIYADH')) {
        // Arabia Standard Time (AST, UTC+3)
        return supportedCountries.firstWhere((c) => c.countryCode == 'SA');
      } else if (offsetMinutes == 240 || tzName.contains('GST') || tzName.contains('DUBAI')) {
        // Gulf Standard Time (GST, UTC+4)
        return supportedCountries.firstWhere((c) => c.countryCode == 'AE');
      } else if (offsetMinutes == 360 || tzName.contains('BST') || tzName.contains('DHAKA')) {
        // Bangladesh Standard Time (BST, UTC+6)
        return supportedCountries.firstWhere((c) => c.countryCode == 'BD');
      } else if ((offsetMinutes == 60 || offsetMinutes == 120) && tzName.contains('BERLIN')) {
        // Germany / Central Europe
        return supportedCountries.firstWhere((c) => c.countryCode == 'DE');
      } else if ((offsetMinutes == 0 || offsetMinutes == 60) && (tzName.contains('LONDON') || tzName.contains('GMT') || tzName.contains('BST'))) {
        // UK
        return supportedCountries.firstWhere((c) => c.countryCode == 'GB');
      }

      // 2. Platform locale check
      if (!kIsWeb) {
        final locale = Platform.localeName.toUpperCase();
        if (locale.contains('PK') || locale.contains('UR')) {
          return supportedCountries.firstWhere((c) => c.countryCode == 'PK');
        } else if (locale.contains('SA') || locale.contains('AR')) {
          return supportedCountries.firstWhere((c) => c.countryCode == 'SA');
        } else if (locale.contains('AE')) {
          return supportedCountries.firstWhere((c) => c.countryCode == 'AE');
        } else if (locale.contains('IN') || locale.contains('HI')) {
          return supportedCountries.firstWhere((c) => c.countryCode == 'IN');
        } else if (locale.contains('BD') || locale.contains('BN')) {
          return supportedCountries.firstWhere((c) => c.countryCode == 'BD');
        } else if (locale.contains('DE')) {
          return supportedCountries.firstWhere((c) => c.countryCode == 'DE');
        } else if (locale.contains('GB') || locale.contains('UK')) {
          return supportedCountries.firstWhere((c) => c.countryCode == 'GB');
        } else if (locale.contains('CA')) {
          return supportedCountries.firstWhere((c) => c.countryCode == 'CA');
        } else if (locale.contains('AU')) {
          return supportedCountries.firstWhere((c) => c.countryCode == 'AU');
        }
      }
    } catch (e) {
      debugPrint('[EmergencyService] Country detection error: $e');
    }

    // Default primary fallback is Pakistan (PK 1122, Urdu)
    return supportedCountries.first;
  }

  /// Attempts to trigger native phone dialer for immediate triage.
  Future<bool> callEmergencyNumber([String? overrideNumber]) async {
    final number = overrideNumber ?? currentCountry.emergencyNumber;
    final cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
    final phoneUri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await launchUrl(phoneUri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (e) {
      debugPrint('[EmergencyService] externalApplication error: $e');
    }

    try {
      if (await canLaunchUrl(phoneUri)) {
        return await launchUrl(phoneUri);
      }
    } catch (e) {
      debugPrint('[EmergencyService] Failed to launch emergency dialer: $e');
    }
    return false;
  }
}
