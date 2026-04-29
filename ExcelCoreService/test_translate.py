import argostranslate.translate

def translate(text, from_code="en", to_code="vi"):
    translatedText = argostranslate.translate.translate(text, from_code, to_code)
    return translatedText

if __name__ == "__main__":
    test_text = "Hello, this is an offline translation test."
    print(f"Original: {test_text}")
    print("Translating...")
    result = translate(test_text)
    print("Translation completed. Checking result.txt...")
    with open("result.txt", "w", encoding="utf-8") as f:
        f.write(f"Original: {test_text}\n")
        f.write(f"Result: {result}\n")
    print(f"Result (encoded): {result.encode('utf-8')}")
