require(["jquery", "requirejs-text!../resources/message.txt"], function($,message) {

  $('#content').append('<h2>VFC! ' + message + '</h2>');

});