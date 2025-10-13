import time
import os
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from .extract import ocr_image, extract_fields, append_contact

INPUT_DIR = os.path.join(os.path.dirname(__file__), 'input')


class ImageHandler(FileSystemEventHandler):
    def on_created(self, event):
        if event.is_directory:
            return
        path = event.src_path
        if path.lower().endswith(('.png', '.jpg', '.jpeg', '.tiff')):
            print('New image detected:', path)
            try:
                text = ocr_image(path)
                contact = extract_fields(text)
                append_contact(contact)
            except Exception as e:
                print('Error processing', path, e)


def ensure_input():
    if not os.path.exists(INPUT_DIR):
        os.makedirs(INPUT_DIR)


if __name__ == '__main__':
    ensure_input()
    event_handler = ImageHandler()
    observer = Observer()
    observer.schedule(event_handler, INPUT_DIR, recursive=False)
    observer.start()
    print('Watching', INPUT_DIR, 'for new images...')
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
