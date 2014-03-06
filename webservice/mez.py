from urllib2 import urlopen

class Mez:

    def __init__(self):
        self.url = 'http://www.mesonet.org/data/public/mesonet/current/current.csv.txt'

    def get_data(self, url = None):
        if not url: url = self.url
        resp = urlopen(url)
        body = resp.read()
        return self._parse_data(body)

    def _set_to_string(self, data_set):
        result_string = ''
        for row in data_set:
            result_string += row[0] + " " + row[1] + " " + row[2] + "\n"

        return result_string

    def _parse_data(self, raw_data):
        result_set = []
        data_lines = raw_data.split("\n")[1:] # split by line and drop headers line (1)
        for l in data_lines:
            values = l.split(',')
            try:
                (result) = values[3], values[4], values[10]
                if values[10] != ' ': result_set.append(result)
            except IndexError:
                pass

        return self._set_to_string(result_set)
