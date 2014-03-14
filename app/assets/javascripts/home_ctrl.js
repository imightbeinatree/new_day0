// app/assets/javascripts/angular/controllers/HomeCtrl.js.coffee

var day_zero = angular.module("day_zero", ['ngResource']);
var Base64 = {


    _keyStr: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",


    encode: function(input) {
        var output = "";
        var chr1, chr2, chr3, enc1, enc2, enc3, enc4;
        var i = 0;

        input = Base64._utf8_encode(input);

        while (i < input.length) {

            chr1 = input.charCodeAt(i++);
            chr2 = input.charCodeAt(i++);
            chr3 = input.charCodeAt(i++);

            enc1 = chr1 >> 2;
            enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
            enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
            enc4 = chr3 & 63;

            if (isNaN(chr2)) {
                enc3 = enc4 = 64;
            } else if (isNaN(chr3)) {
                enc4 = 64;
            }

            output = output + this._keyStr.charAt(enc1) + this._keyStr.charAt(enc2) + this._keyStr.charAt(enc3) + this._keyStr.charAt(enc4);

        }

        return output;
    },


    decode: function(input) {
        var output = "";
        var chr1, chr2, chr3;
        var enc1, enc2, enc3, enc4;
        var i = 0;

        input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");

        while (i < input.length) {

            enc1 = this._keyStr.indexOf(input.charAt(i++));
            enc2 = this._keyStr.indexOf(input.charAt(i++));
            enc3 = this._keyStr.indexOf(input.charAt(i++));
            enc4 = this._keyStr.indexOf(input.charAt(i++));

            chr1 = (enc1 << 2) | (enc2 >> 4);
            chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
            chr3 = ((enc3 & 3) << 6) | enc4;

            output = output + String.fromCharCode(chr1);

            if (enc3 != 64) {
                output = output + String.fromCharCode(chr2);
            }
            if (enc4 != 64) {
                output = output + String.fromCharCode(chr3);
            }

        }

        output = Base64._utf8_decode(output);

        return output;

    },

    _utf8_encode: function(string) {
        string = string.replace(/\r\n/g, "\n");
        var utftext = "";

        for (var n = 0; n < string.length; n++) {

            var c = string.charCodeAt(n);

            if (c < 128) {
                utftext += String.fromCharCode(c);
            }
            else if ((c > 127) && (c < 2048)) {
                utftext += String.fromCharCode((c >> 6) | 192);
                utftext += String.fromCharCode((c & 63) | 128);
            }
            else {
                utftext += String.fromCharCode((c >> 12) | 224);
                utftext += String.fromCharCode(((c >> 6) & 63) | 128);
                utftext += String.fromCharCode((c & 63) | 128);
            }

        }

        return utftext;
    },

    _utf8_decode: function(utftext) {
        var string = "";
        var i = 0;
        var c = c1 = c2 = 0;

        while (i < utftext.length) {

            c = utftext.charCodeAt(i);

            if (c < 128) {
                string += String.fromCharCode(c);
                i++;
            }
            else if ((c > 191) && (c < 224)) {
                c2 = utftext.charCodeAt(i + 1);
                string += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
                i += 2;
            }
            else {
                c2 = utftext.charCodeAt(i + 1);
                c3 = utftext.charCodeAt(i + 2);
                string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
                i += 3;
            }

        }

        return string;
    }

}


day_zero.controller('HomeCtrl', ['$scope', '$http', '$window', function($scope, $http, $window) {
  
  $scope.getData = function(){
    $http.get("http://api.newdayzero.com/authed_request", {})
      .success(function(data, status, headers, config) {
        $scope.data = data;
        $scope.status = status;
        console.log("got success!")
        console.log(data)
      }).error(function(data, status, headers, config) {
        $scope.data = data;
        $scope.status = status;
        console.log("got error!")
        console.log(data)
      });
    };

  $scope.twitter_sign_in_submit = function () {
    $window.sessionStorage = ""
    var consumerKey = encodeURIComponent('VeH9gXLE8Pqg7FXqf4QoA>')
    var consumerSecret = encodeURIComponent('zujxB5wOlRLjDVB8EKPZszD0X2UTGdul9gPk5FsXnkk')
    var credentials = Base64.encode(consumerKey + ':' + consumerSecret)
    // Twitters OAuth service endpoint
    $http.post('http://api.newdayzero.com/oauth/twitter', {})

    .success(function (response) {
      // a successful response will return
      // the "bearer" token which is registered
      // to the $httpProvider
      console.log("twitter success")
    }).error(function (response) {
      // error handling to some meaningful extent
      console.log("twitter error")
    }) 
  };

  $scope.open = function () {

    var popupSize = {
        width: 550,
        height: 550
    };

    document.domain = "newdayzero.com"

    popup = window.open(
                    'http://api.newdayzero.com/provider/auth/twitter',
                    'Authorization',
                    'resizeable=true,width=' + popupSize.width + ',height=' + popupSize.height + ',left='+((window.innerWidth - popupSize.width) / 2)+',top='+((window.innerHeight - popupSize.height) / 2)
                );

    
    popup.focus();

  };

}])

day_zero.controller('UserCtrl', function ($scope, $http, $window) {
  $scope.registration_submit = function () {
    $scope.user = {email: "dave@cloudspace.com", password: "asdfasdf1", password_confirmation: "asdfasdf1"};
    $http
      .post("http://api.newdayzero.com/ajax_create.json", $scope.user)
      .success(function (data, status, headers, config) {
        console.log("token = "+data.token)
        $window.sessionStorage.token = data.token;
        console.log("here is the sign up return");
        console.log(data)
      })
      .error(function (data, status, headers, config) {
        // Erase the token if the user fails to log in
        delete $window.sessionStorage.token;
        console.log("error, here is the sign up error return");  
        console.log(data)
      });
  };

  $scope.sign_in_submit = function () {
    $scope.user = {email: "dave@cloudspace.com", password: "asdfasdf1"};
    $http
      .post("http://api.newdayzero.com/ajax_session_create.json", {user: $scope.user} )
      .success(function (data, status, headers, config) {
        console.log("token = "+data.token)
        $window.sessionStorage.token = data.token;
        console.log("here is the sign in return");
        console.log(data)
      })
      .error(function (data, status, headers, config) {
        // Erase the token if the user fails to log in
        delete $window.sessionStorage.token;
        console.log("error, here is the sign in error return");  
        console.log(data)
      });
  };

});

day_zero.factory('authInterceptor', function ($rootScope, $q, $window) {
  return {
    request: function (config) {
      config.headers = config.headers || {};
      if ($window.sessionStorage.token) {
        console.log("I'm adding the header!")
        config.headers.Authorization = 'Bearer ' + $window.sessionStorage.token;
      }
      return config;
    },
    response: function (response) {
      if (response.status === 401) {
        // handle the case where the user is not authenticated
      }
      return response || $q.when(response);
    }
  };
});

//day_zero.config(function ($httpProvider) {
//  $httpProvider.interceptors.push('authInterceptor');
//});