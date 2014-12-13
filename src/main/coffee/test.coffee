require ["jquery", "requirejs-text!../resources/message.txt"], ($,message) ->

  $('#content').append('<h2>VFC! ' + message + '</h2>')