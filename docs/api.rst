.. _api:

API
===

The API is very basic. By default, there is no API key to access the API, but you can use the :code:`require_appkey` wrapper function around the :code:`TTSData.get` method.

The API has an endpoint called :code:`tts` which returns an audio file. You can return it as an attachment by appending :code:`&attach=true` to the query.

For the toy talking clock, you can pass a 3 or 4 digit number representing the time of day through the `text` query parameter. The synthesizer uses the 24 hour clock, so for example:

`<https://flask-festival-api-starter.herokuapp.com/api/v1/tts?text=333&attach=true>`_ will synthesize the time at 3:33am and send as an attachment.

`<https://flask-festival-api-starter.herokuapp.com/api/v1/tts?text=1533>`_ will synthesize the time at 3:33pm and send the file directly.
