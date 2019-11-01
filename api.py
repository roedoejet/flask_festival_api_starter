''' A barebones Flask API for accessing Festival
'''
import os
import contextlib
from functools import wraps

from sh import Command
from flask import abort, Flask, request, send_file
from flask_restful import Api, reqparse, Resource

FESTIVALDIR = os.getenv('FESTIVALDIR')
MODELPATH = os.getenv('MODELPATH')
VOICEPATH = os.getenv('VOICEPATH')
VOICENAME = os.getenv('VOICENAME')
AUDIODIR = os.getenv('AUDIODIR')

API_KEY = "ThisIsNotASecureKey"

festival = Command(f"{FESTIVALDIR}/bin/festival")
application = Flask(__name__)
api = Api(application)

def require_appkey(view_function):
    @wraps(view_function)
    def decorated_function(*args, **kwargs):
        if API_KEY:
            if 'x-api-key' in request.headers and request.headers['x-api-key'] == API_KEY:
                return view_function(*args, **kwargs)
            else:
                abort(403)
        else:
            return view_function(*args, **kwargs)

    return decorated_function

@contextlib.contextmanager
def cd(path):
    old_path = os.getcwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(old_path)

class TTSData(Resource):
    def __init__(self):
        self.parser = reqparse.RequestParser()
        self.parser.add_argument(
            'text', dest='text',
            type=str, location='args', action='store',
            required=True, help='The text to synthesize'
        )
        self.parser.add_argument(
            'attach', dest='attach',
            type=bool, location='args', default=False,
            required=False, help='Return audio as attachment'
        )

    # @require_appkey
    def get(self):
        args = self.parser.parse_args()
        text = args['text']
        audio_path = os.path.join(AUDIODIR, f"{args['text']}.wav")
        if os.path.exists(audio_path):
            return send_file(audio_path,
                              as_attachment=args['attach'],
                             mimetype='audio/wav',
                             attachment_filename=f"{args['text']}.wav")
        else:
            sub_args = [VOICEPATH,
                        '-b',
                        f"(voice_{VOICENAME}_clunits)",
                        f"(utt.save.wave (SayText \"{text}\") \"{audio_path}\")"]
            with cd(MODELPATH):
                response = festival(sub_args)
                if isinstance(response, str) and 'Unknown' in response:
                    return 404
                else:
                    return send_file(audio_path,
                                      as_attachment=args['attach'],
                                     mimetype='audio/wav',
                                     attachment_filename=f"{args['text']}.wav")

api.add_resource(TTSData, '/api/v1/tts')

if __name__ == '__main__':
    application.run()
