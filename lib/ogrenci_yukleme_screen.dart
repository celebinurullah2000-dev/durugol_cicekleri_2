import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OgrenciYuklemeScreen extends StatefulWidget {
  const OgrenciYuklemeScreen({super.key});

  @override
  State<OgrenciYuklemeScreen> createState() => _OgrenciYuklemeScreenState();
}

class _OgrenciYuklemeScreenState extends State<OgrenciYuklemeScreen> {
  bool _isUploading = false;
  String _durumMesaji = "Yüklemeye hazır (Toplam 822 öğrenci).";

  // Doğrudan firstName, lastName ve password içeren liste
  final List<Map<String, String>> ogrenciListesi = [
    {
      "firstName": "DEFNE",
      "lastName": "AKTÜRK",
      "cinsiyet": "K",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "defne",
    },
    {
      "firstName": "MEVA",
      "lastName": "KARAMEŞE",
      "cinsiyet": "K",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "meva",
    },
    {
      "firstName": "ALYA",
      "lastName": "GEDİK",
      "cinsiyet": "K",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "alya",
    },
    {
      "firstName": "ÖYKÜ MİRA",
      "lastName": "YÜCE",
      "cinsiyet": "K",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "öykümira",
    },
    {
      "firstName": "ZEYNEP",
      "lastName": "SAĞLAM",
      "cinsiyet": "K",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "zeynep",
    },
    {
      "firstName": "HAZAL ECE",
      "lastName": "ÖZDEMİR",
      "cinsiyet": "K",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "hazalece",
    },
    {
      "firstName": "BEYZA",
      "lastName": "KÖSE",
      "cinsiyet": "K",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "beyza",
    },
    {
      "firstName": "LAVİNYA",
      "lastName": "ŞAHİN",
      "cinsiyet": "K",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "lavinya",
    },
    {
      "firstName": "İPEK",
      "lastName": "KÖROĞLU",
      "cinsiyet": "K",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "ipek",
    },
    {
      "firstName": "HİLAL",
      "lastName": "YILDIZ",
      "cinsiyet": "K",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "hilal",
    },
    {
      "firstName": "ELİF",
      "lastName": "AKDOĞAN",
      "cinsiyet": "K",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "elif",
    },
    {
      "firstName": "EYLÜL ECEM",
      "lastName": "TAŞAR",
      "cinsiyet": "K",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "eylülecem",
    },
    {
      "firstName": "AMİNE HÜMA",
      "lastName": "DİLİBAL",
      "cinsiyet": "K",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "aminehüma",
    },
    {
      "firstName": "DURU",
      "lastName": "PULAT",
      "cinsiyet": "K",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "duru",
    },
    {
      "firstName": "HATİCE REYYAN",
      "lastName": "AKBAŞ",
      "cinsiyet": "K",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "haticereyyan",
    },
    {
      "firstName": "ZENNURE",
      "lastName": "TAŞDEMİR",
      "cinsiyet": "K",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "zennure",
    },
    {
      "firstName": "YAMAN",
      "lastName": "GÜZELOLUK",
      "cinsiyet": "E",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "yaman",
    },
    {
      "firstName": "EDİZ",
      "lastName": "KOCA",
      "cinsiyet": "E",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "ediz",
    },
    {
      "firstName": "ÇINAR AZİZ",
      "lastName": "GEDİK",
      "cinsiyet": "E",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "çinaraziz",
    },
    {
      "firstName": "MUHAMMED DENİZ",
      "lastName": "KURNAZ",
      "cinsiyet": "E",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "muhammeddeniz",
    },
    {
      "firstName": "DORUK",
      "lastName": "AKATA",
      "cinsiyet": "E",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "doruk",
    },
    {
      "firstName": "MEHMET ALP",
      "lastName": "ERDEM",
      "cinsiyet": "E",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "mehmetalp",
    },
    {
      "firstName": "FURKAN",
      "lastName": "ZAVALSIZ",
      "cinsiyet": "E",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "furkan",
    },
    {
      "firstName": "İBRAHİM METE",
      "lastName": "SAĞRA",
      "cinsiyet": "E",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "ibrahimmete",
    },
    {
      "firstName": "MİRAN ASAF",
      "lastName": "ALTUNIŞIK",
      "cinsiyet": "E",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "miranasaf",
    },
    {
      "firstName": "MUHAMMED BATU",
      "lastName": "KESKİN",
      "cinsiyet": "E",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "muhammedbatu",
    },
    {
      "firstName": "GÜRKAN TAHA",
      "lastName": "ASLAN",
      "cinsiyet": "E",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "gürkantaha",
    },
    {
      "firstName": "ALİ ASAF",
      "lastName": "KULAKCI",
      "cinsiyet": "E",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "aliasaf",
    },
    {
      "firstName": "ÇINAR ATA",
      "lastName": "ÇARKÇI",
      "cinsiyet": "E",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "çinarata",
    },
    {
      "firstName": "MUHAMMED ALİ",
      "lastName": "GÜZELHAN",
      "cinsiyet": "E",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "muhammedali",
    },
    {
      "firstName": "ZAFER",
      "lastName": "ÖZTÜRK",
      "cinsiyet": "E",
      "classId": "tGXTLucW74nbAIzJIm12",
      "password": "zafer",
    },
    {
      "firstName": "EBRAR AHSEN",
      "lastName": "BAYRAK",

      "cinsiyet": "K",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "ebrarahsen",
    },
    {
      "firstName": "DURU",
      "lastName": "BAFRA",

      "cinsiyet": "K",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "duru",
    },
    {
      "firstName": "MEVA SU",
      "lastName": "BUDAK",

      "cinsiyet": "K",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "mevasu",
    },
    {
      "firstName": "CANSU",
      "lastName": "GÜNDAY",

      "cinsiyet": "K",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "cansu",
    },
    {
      "firstName": "ZEYNEP SENA",
      "lastName": "ÖZTÜRK",

      "cinsiyet": "K",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "zeynepsena",
    },
    {
      "firstName": "SELVA ZEYNEP",
      "lastName": "KARAKIŞLA",

      "cinsiyet": "K",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "selvazeynep",
    },
    {
      "firstName": "DERİN",
      "lastName": "DEDE",

      "cinsiyet": "K",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "derin",
    },
    {
      "firstName": "BESTE ASEL",
      "lastName": "ŞAHİN",

      "cinsiyet": "K",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "besteasel",
    },
    {
      "firstName": "İPEK UMAY",
      "lastName": "TANRIVERMİŞ",

      "cinsiyet": "K",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "ipekumay",
    },
    {
      "firstName": "ZEREN ECE",
      "lastName": "TİKENCE",

      "cinsiyet": "K",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "zerenece",
    },
    {
      "firstName": "ELANUR",
      "lastName": "ÖZBUCAK",

      "cinsiyet": "K",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "elanur",
    },
    {
      "firstName": "HÜMA",
      "lastName": "ER",

      "cinsiyet": "K",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "hüma",
    },
    {
      "firstName": "LİYANUR İZGİ",
      "lastName": "ŞAHİN",

      "cinsiyet": "K",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "liyanurizgi",
    },
    {
      "firstName": "GÜNEŞ LİNA",
      "lastName": "KARADENİZ",

      "cinsiyet": "K",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "güneşlina",
    },
    {
      "firstName": "YAVUZ SELİM",
      "lastName": "AYDIN",

      "cinsiyet": "E",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "yavuzselim",
    },
    {
      "firstName": "HİZİR ALİ",
      "lastName": "EKİN",

      "cinsiyet": "E",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "hizirali",
    },
    {
      "firstName": "KEREM",
      "lastName": "KURT",

      "cinsiyet": "E",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "kerem",
    },
    {
      "firstName": "EGEMEN",
      "lastName": "ÖNER",

      "cinsiyet": "E",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "egemen",
    },
    {
      "firstName": "OĞUZ KAAN",
      "lastName": "ÇELİK",

      "cinsiyet": "E",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "oğuzkaan",
    },
    {
      "firstName": "ÖMER ASAF",
      "lastName": "YAMAN",

      "cinsiyet": "E",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "ömerasaf",
    },
    {
      "firstName": "OZAN",
      "lastName": "KALPAKLIOĞLU",

      "cinsiyet": "E",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "ozan",
    },
    {
      "firstName": "DORUK ALP",
      "lastName": "DUĞAN",

      "cinsiyet": "E",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "dorukalp",
    },
    {
      "firstName": "ÇAĞAN ASLAN",
      "lastName": "ÇETİNKAYA",

      "cinsiyet": "E",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "çağanaslan",
    },
    {
      "firstName": "ÖMER ASLAN",
      "lastName": "BAŞ",

      "cinsiyet": "E",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "ömeraslan",
    },
    {
      "firstName": "EMİR EYMEN",
      "lastName": "YAŞAR",

      "cinsiyet": "E",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "emireymen",
    },
    {
      "firstName": "EMİR",
      "lastName": "SAĞSEN",

      "cinsiyet": "E",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "emir",
    },
    {
      "firstName": "EMİR TİMUR",
      "lastName": "KANBUR",

      "cinsiyet": "E",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "emirtimur",
    },
    {
      "firstName": "EMİRALP",
      "lastName": "PAMUK",

      "cinsiyet": "E",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "emiralp",
    },
    {
      "firstName": "KAAN",
      "lastName": "UZUNLAR",

      "cinsiyet": "E",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "kaan",
    },
    {
      "firstName": "KUZEY",
      "lastName": "KOÇ",

      "cinsiyet": "E",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "kuzey",
    },
    {
      "firstName": "YAVUZ KAAN",
      "lastName": "ŞAHİN",

      "cinsiyet": "E",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "yavuzkaan",
    },
    {
      "firstName": "GÜNEŞ",
      "lastName": "YILMAZ",

      "cinsiyet": "K",
      "classId": "7WZSkVUocJAGtzPj9y1X",
      "password": "güneş",
    },
    {
      "firstName": "ERVA",
      "lastName": "SANCAK",

      "cinsiyet": "K",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "erva",
    },
    {
      "firstName": "MİLA",
      "lastName": "GÜNAYDIN",

      "cinsiyet": "K",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "mila",
    },
    {
      "firstName": "ZÜMRA",
      "lastName": "ER",

      "cinsiyet": "K",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "zümra",
    },
    {
      "firstName": "ECEMSU",
      "lastName": "ELMAS",

      "cinsiyet": "K",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "ecemsu",
    },
    {
      "firstName": "EBRAR BÜŞRA",
      "lastName": "SOKU",

      "cinsiyet": "K",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "ebrarbüşra",
    },
    {
      "firstName": "ALYA NAZ",
      "lastName": "SEVEN",

      "cinsiyet": "K",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "alyanaz",
    },
    {
      "firstName": "EZEL",
      "lastName": "YILMAZ",

      "cinsiyet": "K",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "ezel",
    },
    {
      "firstName": "İKRA HAYAL",
      "lastName": "YILDIRIM",

      "cinsiyet": "K",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "ikrahayal",
    },
    {
      "firstName": "ASEL DURU",
      "lastName": "ALTUNIŞIK",

      "cinsiyet": "K",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "aselduru",
    },
    {
      "firstName": "GÖKÇE ASEL",
      "lastName": "ÇAKMAK",

      "cinsiyet": "K",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "gökçeasel",
    },
    {
      "firstName": "ESLEM ADA",
      "lastName": "SÜME",

      "cinsiyet": "K",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "eslemada",
    },
    {
      "firstName": "KUMSAL",
      "lastName": "ARSLAN",

      "cinsiyet": "K",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "kumsal",
    },
    {
      "firstName": "ZEYNEP",
      "lastName": "GÖKBULUT",

      "cinsiyet": "K",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "zeynep",
    },
    {
      "firstName": "GÖKÇE MELEK",
      "lastName": "GÜL",

      "cinsiyet": "K",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "gökçemelek",
    },
    {
      "firstName": "İDİL ERVA",
      "lastName": "OKUYAN",

      "cinsiyet": "K",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "idilerva",
    },
    {
      "firstName": "TUĞSEM",
      "lastName": "ÇATAL",

      "cinsiyet": "K",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "tuğsem",
    },
    {
      "firstName": "ASEL",
      "lastName": "BULGURU",

      "cinsiyet": "K",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "asel",
    },
    {
      "firstName": "KAYRA TUNA",
      "lastName": "BAŞ",

      "cinsiyet": "E",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "kayratuna",
    },
    {
      "firstName": "İNAN ASLAN",
      "lastName": "ELMAS",

      "cinsiyet": "E",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "inanaslan",
    },
    {
      "firstName": "BAHTİYAR ASAF",
      "lastName": "SOYLU",

      "cinsiyet": "E",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "bahtiyarasaf",
    },
    {
      "firstName": "ATAMAN ERK",
      "lastName": "YILMAZ",

      "cinsiyet": "E",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "atamanerk",
    },
    {
      "firstName": "YUSUF TAHA",
      "lastName": "ALTUNBAŞ",

      "cinsiyet": "E",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "yusuftaha",
    },
    {
      "firstName": "AHMET EFE",
      "lastName": "AYDIN",

      "cinsiyet": "E",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "ahmetefe",
    },
    {
      "firstName": "ASİL ASRIN",
      "lastName": "ALBAYRAK",

      "cinsiyet": "E",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "asilasrin",
    },
    {
      "firstName": "ALPASLAN",
      "lastName": "AKYILDIZ",

      "cinsiyet": "E",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "alpaslan",
    },
    {
      "firstName": "DEMİR",
      "lastName": "TÜRCAN",

      "cinsiyet": "E",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "demir",
    },
    {
      "firstName": "DENİZHAN",
      "lastName": "OCAK",

      "cinsiyet": "E",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "denizhan",
    },
    {
      "firstName": "DORUK",
      "lastName": "ELİKCİOĞLU",

      "cinsiyet": "E",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "doruk",
    },
    {
      "firstName": "TOPRAK",
      "lastName": "ATEŞ",

      "cinsiyet": "E",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "toprak",
    },
    {
      "firstName": "YUSUF POYRAZ",
      "lastName": "ÇAKIR",

      "cinsiyet": "E",
      "classId": "f34faXbksjn3ay7WAsZP",
      "password": "yusufpoyraz",
    },
    {
      "firstName": "ESLEM",
      "lastName": "AKOLUK",

      "cinsiyet": "K",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "eslem",
    },
    {
      "firstName": "SERENAY",
      "lastName": "KARA",

      "cinsiyet": "K",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "serenay",
    },
    {
      "firstName": "MİRA",
      "lastName": "YÜKSEL",

      "cinsiyet": "K",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "mira",
    },
    {
      "firstName": "ZÜLEYHA",
      "lastName": "ŞAHİN",

      "cinsiyet": "K",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "züleyha",
    },
    {
      "firstName": "ÖYKÜ",
      "lastName": "ÖZEL",

      "cinsiyet": "K",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "öykü",
    },
    {
      "firstName": "MELİKE BAHAR",
      "lastName": "ÖZTÜRK",

      "cinsiyet": "K",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "melikebahar",
    },
    {
      "firstName": "İPEK MEVA",
      "lastName": "DEMİR",

      "cinsiyet": "K",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "ipekmeva",
    },
    {
      "firstName": "EYLÜL",
      "lastName": "BAYAZIDOĞLU",

      "cinsiyet": "K",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "eylül",
    },
    {
      "firstName": "ALYA",
      "lastName": "ALVER",

      "cinsiyet": "K",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "alya",
    },
    {
      "firstName": "ASYA EYLÜL",
      "lastName": "ÖZTÜRK",

      "cinsiyet": "K",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "asyaeylül",
    },
    {
      "firstName": "AYŞE SARE",
      "lastName": "TEKİN",

      "cinsiyet": "K",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "ayşesare",
    },
    {
      "firstName": "BEYZA SARE",
      "lastName": "BAŞ",

      "cinsiyet": "K",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "beyzasare",
    },
    {
      "firstName": "MİLA",
      "lastName": "TİRYAKİ",

      "cinsiyet": "K",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "mila",
    },
    {
      "firstName": "SENANUR",
      "lastName": "YILMAZ",

      "cinsiyet": "K",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "senanur",
    },
    {
      "firstName": "SERRA ALYA",
      "lastName": "DURU",

      "cinsiyet": "K",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "serraalya",
    },
    {
      "firstName": "DENİZ",
      "lastName": "BAKAÇ",

      "cinsiyet": "E",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "deniz",
    },
    {
      "firstName": "KUZEY ARAS",
      "lastName": "DEMİRBAŞ",

      "cinsiyet": "E",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "kuzeyaras",
    },
    {
      "firstName": "AREL",
      "lastName": "HÜLÜR",

      "cinsiyet": "E",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "arel",
    },
    {
      "firstName": "SİRAC",
      "lastName": "GÜL",

      "cinsiyet": "E",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "sirac",
    },
    {
      "firstName": "EMİN BERK",
      "lastName": "ÇELEBİ",

      "cinsiyet": "E",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "eminberk",
    },
    {
      "firstName": "URAS",
      "lastName": "DÖNMEZ",

      "cinsiyet": "E",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "uras",
    },
    {
      "firstName": "DENİZ EFE",
      "lastName": "KURU",

      "cinsiyet": "E",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "denizefe",
    },
    {
      "firstName": "UTKU EMİR",
      "lastName": "ÇAKIR",

      "cinsiyet": "E",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "utkuemir",
    },
    {
      "firstName": "GÖKTUĞ",
      "lastName": "GÖKÇE",

      "cinsiyet": "E",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "göktuğ",
    },
    {
      "firstName": "YİĞİT ALP",
      "lastName": "BOZKURT",

      "cinsiyet": "E",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "yiğitalp",
    },
    {
      "firstName": "KERİM",
      "lastName": "GÜNDÜZ",

      "cinsiyet": "E",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "kerim",
    },
    {
      "firstName": "KEREM",
      "lastName": "GÜNDÜZ",

      "cinsiyet": "E",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "kerem",
    },
    {
      "firstName": "ATAHAN",
      "lastName": "DANIŞ",

      "cinsiyet": "E",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "atahan",
    },
    {
      "firstName": "FURKAN",
      "lastName": "YILMAZ",

      "cinsiyet": "E",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "furkan",
    },
    {
      "firstName": "ÖMER AGAH",
      "lastName": "İŞLER",

      "cinsiyet": "E",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "ömeragah",
    },
    {
      "firstName": "YAĞIZ",
      "lastName": "İNCE",

      "cinsiyet": "E",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "yağız",
    },
    {
      "firstName": "BULUT İHSAN",
      "lastName": "KELEBEK",

      "cinsiyet": "E",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "bulutihsan",
    },
    {
      "firstName": "ARDA TUĞRA",
      "lastName": "YAKIŞAN",

      "cinsiyet": "E",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "ardatuğra",
    },
    {
      "firstName": "MUSTAFA CAN",
      "lastName": "PALAVAR",

      "cinsiyet": "E",
      "classId": "TU1vvDUl3eJV7HYUswVa",
      "password": "mustafacan",
    },
    {
      "firstName": "ASUDE HÜMA",
      "lastName": "DURSUN",

      "cinsiyet": "K",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "asudehüma",
    },
    {
      "firstName": "BEYZA GÖKSU",
      "lastName": "ALKURT",

      "cinsiyet": "K",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "beyzagöksu",
    },
    {
      "firstName": "EYLÜL SEVİM",
      "lastName": "DUMAN",

      "cinsiyet": "K",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "eylülsevim",
    },
    {
      "firstName": "ELİSA",
      "lastName": "ÖZDEMİR",

      "cinsiyet": "K",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "elisa",
    },
    {
      "firstName": "ELİF LİNA",
      "lastName": "TUZLUSU",

      "cinsiyet": "K",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "eliflina",
    },
    {
      "firstName": "YAĞMUR",
      "lastName": "GÖZPINAR",

      "cinsiyet": "K",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "yağmur",
    },
    {
      "firstName": "EBRAR TUANA",
      "lastName": "ŞENEL",

      "cinsiyet": "K",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "ebrartuana",
    },
    {
      "firstName": "ALYA",
      "lastName": "TÜRCAN",

      "cinsiyet": "K",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "alya",
    },
    {
      "firstName": "ÖYKÜ",
      "lastName": "ÇAPKIN",

      "cinsiyet": "K",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "öykü",
    },
    {
      "firstName": "ÖZGÜ",
      "lastName": "ÇAVAŞ",

      "cinsiyet": "K",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "özgü",
    },
    {
      "firstName": "ALİNA",
      "lastName": "KURT",

      "cinsiyet": "K",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "alina",
    },
    {
      "firstName": "EBRAR",
      "lastName": "ÖZDEN",

      "cinsiyet": "K",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "ebrar",
    },
    {
      "firstName": "ELİF DEREN",
      "lastName": "BOLAT",

      "cinsiyet": "K",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "elifderen",
    },
    {
      "firstName": "İPEK NEVA",
      "lastName": "GÜNAYDIN",

      "cinsiyet": "K",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "ipekneva",
    },
    {
      "firstName": "MELEK NİL",
      "lastName": "GÜNAYDIN",

      "cinsiyet": "K",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "meleknil",
    },
    {
      "firstName": "ZEYNEP",
      "lastName": "SAKA",

      "cinsiyet": "K",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "zeynep",
    },
    {
      "firstName": "ZEYNEP HAFSA",
      "lastName": "KILIÇ",

      "cinsiyet": "K",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "zeynephafsa",
    },
    {
      "firstName": "ALİ KEREM",
      "lastName": "KARAGÖL",

      "cinsiyet": "E",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "alikerem",
    },
    {
      "firstName": "BAYRAM YALIN",
      "lastName": "USTA",

      "cinsiyet": "E",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "bayramyalin",
    },
    {
      "firstName": "AHMET ARAS",
      "lastName": "AK",

      "cinsiyet": "E",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "ahmetaras",
    },
    {
      "firstName": "MİRAÇ ALİ",
      "lastName": "KURNAZ",

      "cinsiyet": "E",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "miraçali",
    },
    {
      "firstName": "YİĞİT ALP",
      "lastName": "AVCI",

      "cinsiyet": "E",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "yiğitalp",
    },
    {
      "firstName": "ERTUĞRUL",
      "lastName": "ASAL",

      "cinsiyet": "E",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "ertuğrul",
    },
    {
      "firstName": "İSMET",
      "lastName": "ÖZMEN",

      "cinsiyet": "E",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "ismet",
    },
    {
      "firstName": "ATA",
      "lastName": "ÖZPEHLİVAN",

      "cinsiyet": "E",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "ata",
    },
    {
      "firstName": "ÇAĞLAR ALP",
      "lastName": "ATİNKAYA",

      "cinsiyet": "E",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "çağlaralp",
    },
    {
      "firstName": "DEMİR",
      "lastName": "BEŞİRLİ",

      "cinsiyet": "E",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "demir",
    },
    {
      "firstName": "KAĞAN",
      "lastName": "UĞURLU",

      "cinsiyet": "E",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "kağan",
    },
    {
      "firstName": "ÖMER ASAF",
      "lastName": "APAYDIN",

      "cinsiyet": "E",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "ömerasaf",
    },
    {
      "firstName": "SARP",
      "lastName": "POYRAZ",

      "cinsiyet": "E",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "sarp",
    },
    {
      "firstName": "ABDÜLKERİM",
      "lastName": "KAYKANA",

      "cinsiyet": "E",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "abdülkerim",
    },
    {
      "firstName": "AYAZ",
      "lastName": "ÖZATA",

      "cinsiyet": "E",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "ayaz",
    },
    {
      "firstName": "ÇINAR ALP",
      "lastName": "GENÇALİOĞLU",

      "cinsiyet": "E",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "çinaralp",
    },
    {
      "firstName": "MEHMET EFE",
      "lastName": "ÖZTÜRK",

      "cinsiyet": "E",
      "classId": "k5UNiQIMBdDHCd8Soo8E",
      "password": "mehmetefe",
    },
    {
      "firstName": "KARDELEN",
      "lastName": "KÖKSAL",

      "cinsiyet": "K",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "kardelen",
    },
    {
      "firstName": "ZEYNEP DURU",
      "lastName": "BÖLEK",

      "cinsiyet": "K",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "zeynepduru",
    },
    {
      "firstName": "BERİL",
      "lastName": "BAYHAN",

      "cinsiyet": "K",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "beril",
    },
    {
      "firstName": "ASYA",
      "lastName": "ÇALIŞKAN",

      "cinsiyet": "K",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "asya",
    },
    {
      "firstName": "EKİN",
      "lastName": "TAŞ",

      "cinsiyet": "K",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "ekin",
    },
    {
      "firstName": "ZEYNEP MİRA",
      "lastName": "YURTSEVEN",

      "cinsiyet": "K",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "zeynepmira",
    },
    {
      "firstName": "ZEYNEP",
      "lastName": "ÇAKIR",

      "cinsiyet": "K",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "zeynep",
    },
    {
      "firstName": "ELİF",
      "lastName": "ADIGÜZEL",

      "cinsiyet": "K",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "elif",
    },
    {
      "firstName": "AHSEN",
      "lastName": "AKDOĞAN",

      "cinsiyet": "K",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "ahsen",
    },
    {
      "firstName": "HAFSA ZEHRA",
      "lastName": "KESKİN",

      "cinsiyet": "K",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "hafsazehra",
    },
    {
      "firstName": "İLKEM NİL",
      "lastName": "AKMAN",

      "cinsiyet": "K",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "ilkemnil",
    },
    {
      "firstName": "REYYAN MEVA",
      "lastName": "KARA",

      "cinsiyet": "K",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "reyyanmeva",
    },
    {
      "firstName": "ŞEYMA",
      "lastName": "TANIŞ",

      "cinsiyet": "K",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "şeyma",
    },
    {
      "firstName": "AZRA",
      "lastName": "SEMİZ",

      "cinsiyet": "K",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "azra",
    },
    {
      "firstName": "MUHAMMED TALHA",
      "lastName": "GÜNEŞ",

      "cinsiyet": "E",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "muhammedtalha",
    },
    {
      "firstName": "MUHAMMED ERİM",
      "lastName": "TURAN",

      "cinsiyet": "E",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "muhammederim",
    },
    {
      "firstName": "ÇAĞAN ULAŞ",
      "lastName": "SÜRGÜLÜ",

      "cinsiyet": "E",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "çağanulaş",
    },
    {
      "firstName": "ALİ",
      "lastName": "ARSLANTÜRK",

      "cinsiyet": "E",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "ali",
    },
    {
      "firstName": "EMİR ÜNAL",
      "lastName": "SOYSAL",

      "cinsiyet": "E",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "emirünal",
    },
    {
      "firstName": "ENSAR TAHA",
      "lastName": "CENGİZ",

      "cinsiyet": "E",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "ensartaha",
    },
    {
      "firstName": "ALİ HAMZA",
      "lastName": "ACAR",

      "cinsiyet": "E",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "alihamza",
    },
    {
      "firstName": "POYRAZ",
      "lastName": "BAHTİYAR",

      "cinsiyet": "E",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "poyraz",
    },
    {
      "firstName": "ATLAS",
      "lastName": "İNCE",

      "cinsiyet": "E",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "atlas",
    },
    {
      "firstName": "ATA",
      "lastName": "KILIÇ",

      "cinsiyet": "E",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "ata",
    },
    {
      "firstName": "EYMEN",
      "lastName": "ERKEK",

      "cinsiyet": "E",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "eymen",
    },
    {
      "firstName": "DENİZ",
      "lastName": "AKSU",

      "cinsiyet": "E",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "deniz",
    },
    {
      "firstName": "BURAK",
      "lastName": "SAKA",

      "cinsiyet": "E",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "burak",
    },
    {
      "firstName": "MUSTAFA EDİZ",
      "lastName": "TURAN",

      "cinsiyet": "E",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "mustafaediz",
    },
    {
      "firstName": "UTKU",
      "lastName": "KAYMAZ",

      "cinsiyet": "E",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "utku",
    },
    {
      "firstName": "YAMAÇ",
      "lastName": "KILIÇ",

      "cinsiyet": "E",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "yamaç",
    },
    {
      "firstName": "YAVUZ SELİM",
      "lastName": "ÖZTÜRK",

      "cinsiyet": "E",
      "classId": "sBGYab6r5KRTAznooQI5",
      "password": "yavuzselim",
    },
    {
      "firstName": "DERİN",
      "lastName": "AKBULUT",

      "cinsiyet": "K",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "derin",
    },
    {
      "firstName": "NİHAN",
      "lastName": "KIR",

      "cinsiyet": "K",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "nihan",
    },
    {
      "firstName": "ZEYNEP ELA",
      "lastName": "ŞENGÜN",

      "cinsiyet": "K",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "zeynepela",
    },
    {
      "firstName": "ECREN",
      "lastName": "ÖZKAN",

      "cinsiyet": "K",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "ecren",
    },
    {
      "firstName": "CEYLAN LENA",
      "lastName": "DENİZ",

      "cinsiyet": "K",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "ceylanlena",
    },
    {
      "firstName": "AYŞE",
      "lastName": "KARGİ",

      "cinsiyet": "K",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "ayşe",
    },
    {
      "firstName": "BERRA",
      "lastName": "TURAN",

      "cinsiyet": "K",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "berra",
    },
    {
      "firstName": "İKRA",
      "lastName": "DİLAVER",

      "cinsiyet": "K",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "ikra",
    },
    {
      "firstName": "BİLGE HÜMA",
      "lastName": "TÜRKMEN",

      "cinsiyet": "K",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "bilgehüma",
    },
    {
      "firstName": "YAĞMUR",
      "lastName": "ATAMAN",

      "cinsiyet": "K",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "yağmur",
    },
    {
      "firstName": "EBREN AMİNE",
      "lastName": "DOĞAN",

      "cinsiyet": "K",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "ebrenamine",
    },
    {
      "firstName": "TUNAY",
      "lastName": "GÜNDOĞDU",

      "cinsiyet": "K",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "tunay",
    },
    {
      "firstName": "ARYA SU",
      "lastName": "CANDAN",

      "cinsiyet": "K",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "aryasu",
    },
    {
      "firstName": "ELİF ZÜMRA",
      "lastName": "ÖZDEN",

      "cinsiyet": "K",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "elifzümra",
    },
    {
      "firstName": "MİRAY ESLEM",
      "lastName": "KEPENEK",

      "cinsiyet": "K",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "mirayeslem",
    },
    {
      "firstName": "ZÜMRA",
      "lastName": "AYDINHAN",

      "cinsiyet": "K",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "zümra",
    },
    {
      "firstName": "GÖKAY",
      "lastName": "ALTINDEĞER",

      "cinsiyet": "E",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "gökay",
    },
    {
      "firstName": "YAHYA",
      "lastName": "YAŞA",

      "cinsiyet": "E",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "yahya",
    },
    {
      "firstName": "MİRAÇ EFE",
      "lastName": "SAĞSEN",

      "cinsiyet": "E",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "miraçefe",
    },
    {
      "firstName": "URAS",
      "lastName": "KILIÇ",

      "cinsiyet": "E",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "uras",
    },
    {
      "firstName": "MEHMET SELİM",
      "lastName": "YILMAZ",

      "cinsiyet": "E",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "mehmetselim",
    },
    {
      "firstName": "DEMİR URAS",
      "lastName": "ÖZİPEK",

      "cinsiyet": "E",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "demiruras",
    },
    {
      "firstName": "DORUK SELAMİ",
      "lastName": "ERSÖZ",

      "cinsiyet": "E",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "dorukselami",
    },
    {
      "firstName": "CAN",
      "lastName": "GÜVELİ",

      "cinsiyet": "E",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "can",
    },
    {
      "firstName": "OKTAY TALHA",
      "lastName": "EV",

      "cinsiyet": "E",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "oktaytalha",
    },
    {
      "firstName": "YAVUZ",
      "lastName": "ŞENYURT",

      "cinsiyet": "E",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "yavuz",
    },
    {
      "firstName": "FURKAN CAN",
      "lastName": "GÖNÜL",

      "cinsiyet": "E",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "furkancan",
    },
    {
      "firstName": "YUSUF KEREM",
      "lastName": "GÜNGÖR",

      "cinsiyet": "E",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "yusufkerem",
    },
    {
      "firstName": "DORUK AZMİ",
      "lastName": "GÖÇ",

      "cinsiyet": "E",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "dorukazmi",
    },
    {
      "firstName": "SEMİH",
      "lastName": "KUVAN",

      "cinsiyet": "E",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "semih",
    },
    {
      "firstName": "ASLAN",
      "lastName": "DÖNMEZ",

      "cinsiyet": "E",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "aslan",
    },
    {
      "firstName": "DENİZ",
      "lastName": "KARAOĞLU",

      "cinsiyet": "E",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "deniz",
    },
    {
      "firstName": "EREN ENGİN",
      "lastName": "KEPENEK",

      "cinsiyet": "E",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "erenengin",
    },
    {
      "firstName": "ATEŞ",
      "lastName": "KAVGACI",

      "cinsiyet": "E",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "ateş",
    },
    {
      "firstName": "YAMAN",
      "lastName": "AKGÜL",

      "cinsiyet": "E",
      "classId": "zDqrDpfK2c2JApWZKcTS",
      "password": "yaman",
    },
  ];

  Future<void> _ogrencileriTopluYukle() async {
    setState(() {
      _isUploading = true;
      _durumMesaji = "Öğrenciler Firestore'a yükleniyor...";
    });

    try {
      final firestore = FirebaseFirestore.instance;
      int sayac = 0;

      for (var ogrenci in ogrenciListesi) {
        String firstName = ogrenci["firstName"] ?? "";
        String lastName = ogrenci["lastName"] ?? "";
        String password = ogrenci["password"] ?? "";
        String hedefClassId = ogrenci["classId"] ?? "";
        String cinsiyet = ogrenci["cinsiyet"] ?? "K";

        // Doğrudan listedeki alanları kullanarak Firestore'a kayıt
        await firestore.collection('students').add({
          'classId': hedefClassId,
          'firstName': firstName,
          'lastName': lastName,
          'gender': cinsiyet,
          'password': password,
          'tc': '',
          'schoolNumber': '',
          'dogumTarihi': '',
          'anneAdi': '',
          'anneCep': '',
          'anneMeslegi': '',
          'babaAdi': '',
          'babaCep': '',
          'babaMeslegi': '',
          'kardesleri': '',
          'hasBeenOnDuty': false,
          'nobetMusait': true,
          'profileImageUrl': '',
          'resimBase64': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
        sayac++;
      }

      setState(() {
        _durumMesaji = "Başarıyla $sayac öğrenci tüm alanlarıyla yüklendi!";
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _durumMesaji = "Hata oluştu: $e";
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("2, 3 ve 4. Sınıflar Toplu Yükleme"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              _durumMesaji,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: ogrenciListesi.length,
                itemBuilder: (context, index) {
                  final o = ogrenciListesi[index];
                  String adSoyad = "${o["firstName"]} ${o["lastName"]}";
                  String sifre = o["password"] ?? "";
                  String sinif = o["sinif"] ?? "";

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: o["cinsiyet"] == "K"
                            ? Colors.pink[100]
                            : Colors.blue[100],
                        child: Text(sinif),
                      ),
                      title: Text(adSoyad),
                      subtitle: Text(
                        "Sınıf: $sinif | Cinsiyet: ${o["cinsiyet"]} | Şifre: $sifre",
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isUploading ? null : _ogrencileriTopluYukle,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Tüm Öğrencileri Firestore'a Yükle",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
