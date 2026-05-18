import os
import io
import uuid
import base64
import httpx
from fashn import AsyncFashn
from PIL import Image, ImageOps
from dotenv import load_dotenv

load_dotenv()

# Maximum dimension (width or height) for images sent to Fashn.
# Keeps payload small and prevents write-timeouts on upload.
MAX_IMAGE_DIMENSION = 1024
JPEG_QUALITY = 85


class VTOService:
    def __init__(self):
        self.fashn_api_key = os.getenv("FASHN_API_KEY")
        self.fashn_client = None
        if self.fashn_api_key:
            try:
                self.fashn_client = AsyncFashn(api_key=self.fashn_api_key)
                print("Fashn API client configured successfully.")
            except Exception as e:
                print(f"WARNING: Could not initialize Fashn Client: {e}")
        else:
            print("WARNING: FASHN_API_KEY not set in .env. VTO will not work.")

    # ------------------------------------------------------------------ #
    #  Image helpers                                                      #
    # ------------------------------------------------------------------ #

    @staticmethod
    def _compress_image(image_bytes: bytes) -> bytes:
        """
        Open an image from bytes, resize so the longest side ≤ MAX_IMAGE_DIMENSION,
        and return JPEG bytes at JPEG_QUALITY.
        """
        img = Image.open(io.BytesIO(image_bytes))
        img = ImageOps.exif_transpose(img)
        img = img.convert("RGB")  # ensure no alpha channel for JPEG

        # Resize while preserving aspect ratio
        w, h = img.size
        if max(w, h) > MAX_IMAGE_DIMENSION:
            scale = MAX_IMAGE_DIMENSION / max(w, h)
            img = img.resize((int(w * scale), int(h * scale)), Image.LANCZOS)

        buf = io.BytesIO()
        img.save(buf, format="JPEG", quality=JPEG_QUALITY)
        return buf.getvalue()

    def _bytes_to_data_uri(self, image_bytes: bytes) -> str:
        """Convert image bytes to a compressed base64 data URI."""
        jpeg_bytes = self._compress_image(image_bytes)
        b64 = base64.b64encode(jpeg_bytes).decode("utf-8")
        return f"data:image/jpeg;base64,{b64}"

    # ------------------------------------------------------------------ #
    #  Main entry point                                                   #
    # ------------------------------------------------------------------ #

    async def process_try_on(self, person_bytes: bytes, cloth_bytes: bytes, category: str = "auto"):
        """
        Process the virtual try-on using Fashn.ai's API.
        """
        try:
            if not self.fashn_client:
                if not self.fashn_api_key:
                    raise Exception("FASHN_API_KEY not set. Please add it to your .env file.")
                self.fashn_client = AsyncFashn(api_key=self.fashn_api_key)

            # Compress & convert images to data URIs (Fashn accepts base64 data URIs)
            print("  → Preparing images for Fashn.ai...")
            person_data_uri = self._bytes_to_data_uri(person_bytes)
            cloth_data_uri = self._bytes_to_data_uri(cloth_bytes)

            # Validate category
            valid_categories = ["tops", "bottoms", "one-pieces", "auto"]
            if category not in valid_categories:
                category = "auto"

            print(f"  → Sending to Fashn.ai (category={category}, mode=quality)...")

            # Use subscribe() to wait for the prediction to complete
            prediction = await self.fashn_client.predictions.subscribe(
                model_name="tryon-v1.6",
                inputs={
                    "model_image": person_data_uri,
                    "garment_image": cloth_data_uri,
                    "category": category,
                    "mode": "quality",
                    "garment_photo_type": "auto",
                }
            )

            if prediction.status != "completed":
                error_msg = prediction.error.message if prediction.error else "Unknown error"
                print(f"  → Fashn.ai failed: {error_msg}")
                friendly_msg = self._get_friendly_error(error_msg)
                raise Exception(friendly_msg)

            # Fashn returns a list of output URLs
            output_url = prediction.output[0]
            print(f"  → Fashn.ai returned result URL: {output_url}")

            # Download the result image into memory
            async with httpx.AsyncClient(timeout=120.0) as client:
                response = await client.get(output_url)
                response.raise_for_status()
                # Encode as base64 for the mobile app
                result_b64 = base64.b64encode(response.content).decode("utf-8")

            print("  → VTO processing complete!")
            return {
                "success": True,
                "message": "Virtual Try-On generated successfully (via Fashn.ai)",
                "result_image_base64": result_b64,
            }

        except Exception as e:
            print(f"VTO Error: {str(e)}")
            import traceback
            traceback.print_exc()
            return {
                "success": False,
                "message": str(e),
            }

    @staticmethod
    def _get_friendly_error(raw_error: str) -> str:
        """Convert technical Fashn.ai errors into simple, user-friendly messages."""
        raw = raw_error.lower()

        if "body pose" in raw or "detect body" in raw:
            return "We couldn't detect a person in your photo. Please use a clear photo showing your upper body or full body."
        if "garment" in raw:
            return "We couldn't detect the clothing item. Please use a clear photo of the garment on a flat surface or mannequin."
        if "nsfw" in raw or "inappropriate" in raw:
            return "This image cannot be processed. Please use an appropriate photo."
        if "timeout" in raw or "timed out" in raw:
            return "The server took too long to respond. Please try again in a moment."
        if "rate limit" in raw:
            return "Too many requests. Please wait a moment and try again."

        return f"Something went wrong while generating your try-on. Please try again with a different photo."


vto_service = VTOService()
