import os
import tempfile
from pdf2image import convert_from_path
from PIL import Image
from moviepy import VideoFileClip  # corrected import

def generate_image_thumbnail(file_path, output_path=None, size=(180, 200)):
    try:
        with Image.open(file_path) as img:
            img.thumbnail(size)  # preserve aspect ratio
            if output_path is None:
                with tempfile.NamedTemporaryFile(delete=False, suffix=".png") as tmp_file:
                    img.save(tmp_file, "PNG")
                    return tmp_file.name
            else:
                img.save(output_path, "PNG")
                return output_path
    except Exception as e:
        print(f"Image thumbnail error: {e}")
        return None

def generate_pdf_thumbnail(file_path, output_path=None, size=(180, 200)):
    try:
        images = convert_from_path(file_path, first_page=1, last_page=1)
        img = images[0]
        img.thumbnail(size)  # preserve aspect ratio
        if output_path is None:
            with tempfile.NamedTemporaryFile(delete=False, suffix='.png') as tmp_file:
                img.save(tmp_file, 'PNG')
                return tmp_file.name
        else:
            img.save(output_path, 'PNG')
            return output_path
    except Exception as e:
        print(f"Error generating thumbnail for PDF: {e}")
        return None

def generate_video_thumbnail(file_path, output_path=None, size=(180, 200)):
    try:
        clip = VideoFileClip(file_path)
        frame = clip.get_frame(1)
        image = Image.fromarray(frame)
        image.thumbnail(size)  # preserve aspect ratio
        if output_path is None:
            with tempfile.NamedTemporaryFile(delete=False, suffix='.jpg') as tmp_file:
                image.save(tmp_file, 'JPEG')
                return tmp_file.name
        else:
            image.save(output_path, 'JPEG')
            return output_path
    except Exception as e:
        print(f"Error generating thumbnail for video: {e}")
        return None

def generate_thumbnail(file_path, output_path=None):
    file_path_lower = file_path.lower()
    if file_path_lower.endswith('.pdf'):
        return generate_pdf_thumbnail(file_path, output_path)
    elif file_path_lower.endswith(('.mp4', '.mov', '.mkv')):
        return generate_video_thumbnail(file_path, output_path)
    elif file_path_lower.endswith(('.png', '.jpg', '.jpeg')):
        return generate_image_thumbnail(file_path, output_path)
    else:
        return None
