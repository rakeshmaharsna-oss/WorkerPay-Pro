class ImageService {
  ImageService._();

  static final ImageService instance = ImageService._();

  // Worker Pay के core version में अभी image upload की जरूरत नहीं है.
  // यह service future use के लिए रखी गई है.

  Future<String?> pickImage() async {
    return null;
  }
}
