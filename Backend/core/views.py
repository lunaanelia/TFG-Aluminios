import requests

from rest_framework.views import APIView
from rest_framework.response import Response


class BuscarDireccionView(APIView):
    def get(self, request):
        query = request.GET.get('q')

        if not query:
            return Response([])
        

        url = ( "https://nominatim.openstreetmap.org/search")

        params = {
            'q': query,
            'format': 'json',
            'countrycodes': 'es',
            'limit': 5,
        }

        headers = {'User-Agent' : 'AluminiosApp/1.0 ' '(tfgalba1@gmail.com)'}

        response = requests.get(
            url, 
            params = params,
            headers = headers,
            timeout=10
        )

        try:

            data = response.json()
            return Response(data)

        except Exception as e:
            print(e)
            return Response({'error':'Error en Nominatim'}, status=500)