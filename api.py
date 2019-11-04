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

festival = Command("{}/bin/festival".format(FESTIVALDIR))
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

def digits_to_time(dig: str):
    ''' Turns the time requested into the proper format that 'saythistime' function expects in Festival
        
        >>> digits_to_time('111')
        '01:11'
    '''
    if len(dig) < 3 or len(dig) > 4:
        abort(400)
    if len(dig) == 3:
        dig = '0' + dig
    return dig[:2] + ':' + dig[2:]

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
        fname = "{}.wav".format(args['text'])
        audio_path = os.path.join(AUDIODIR, fname)
        if os.path.exists(audio_path):
            return send_file(audio_path,
                              as_attachment=args['attach'],
                             mimetype='audio/wav',
                             attachment_filename=fname)
        else:
            sub_args = [VOICEPATH,
                        '-b',
                        "(voice_{})".format(VOICENAME),
                        # I am using 'saythistime' because that is the function used
                        # by the Festival limited domain synthesizer for the talking clock in my model
                        # The function can be found here: model/eng_clock/festvox/nrc_time_ap.scm
                        # If you need your own function you can just swap this out.
                        "(utt.save.wave (saythistime \"{}\") \"{}\")".format(digits_to_time(text), audio_path)]
            with cd(MODELPATH):
                response = festival(sub_args)
                if isinstance(response, str) and 'Unknown' in response:
                    return 404
                else:
                    return send_file(audio_path,
                                      as_attachment=args['attach'],
                                     mimetype='audio/wav',
                                     attachment_filename=fname)

api.add_resource(TTSData, '/api/v1/tts')

if __name__ == '__main__':
    application.run()
