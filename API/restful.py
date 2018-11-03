from bottle import run

flights = [{'start' : 'Houston', 'end': 'New York'},
           {'start': 'New York', 'end': 'Houston'}]

run(reLoader=True, debug=True)