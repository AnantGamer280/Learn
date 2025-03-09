from flask import Flask, request, render_template_string
import os
import subprocess

app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

HTML_TEMPLATE = '''
<!DOCTYPE html>
<html>
<head>
    <title>Live Stream App</title>
</head>
<body>
    <h1>Upload Video for Live Stream</h1>
    <form action="/upload" method="post" enctype="multipart/form-data">
        <input type="file" name="video">
        <input type="submit" value="Upload">
    </form>
    <br>
    <form action="/start_stream" method="post">
        <input type="text" name="stream_key" placeholder="Enter YouTube Stream Key">
        <input type="submit" value="Start Live">
    </form>
</body>
</html>
'''

@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE)

@app.route('/upload', methods=['POST'])
def upload():
    if 'video' not in request.files:
        return "No file part"
    file = request.files['video']
    if file.filename == '':
        return "No selected file"
    filepath = os.path.join(UPLOAD_FOLDER, file.filename)
    file.save(filepath)
    return "Upload Successful!"

@app.route('/start_stream', methods=['POST'])
def start_stream():
    stream_key = request.form.get('stream_key')
    if not stream_key:
        return "Stream key required"
    
    video_path = next((f for f in os.listdir(UPLOAD_FOLDER) if f.endswith('.mp4')), None)
    if not video_path:
        return "No uploaded video found"
    
    video_file = os.path.join(UPLOAD_FOLDER, video_path)
    command = [
        'ffmpeg', '-re', '-i', video_file, '-vcodec', 'libx264', '-preset', 'ultrafast', '-maxrate', '3000k',
        '-bufsize', '6000k', '-pix_fmt', 'yuv420p', '-g', '60', '-acodec', 'aac', '-b:a', '128k', '-f', 'flv',
        f'rtmp://a.rtmp.youtube.com/live2/{stream_key}'
    ]
    subprocess.Popen(command)
    return "Live stream started!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
