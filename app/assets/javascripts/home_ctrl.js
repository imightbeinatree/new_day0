// app/assets/javascripts/angular/controllers/HomeCtrl.js.coffee

var day_zero = angular.module("day_zero", ['ngResource']);

day_zero.controller('HomeCtrl', ['$scope', '$http', function($scope, $http) {
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
}])

day_zero.controller('UserCtrl', function ($scope, $http, $window) {
  $scope.user = {email: "dave@cloudspace.com", password: "asdfasdf1", password_confirmation: "asdfasdf1"};
  $scope.registration_submit = function () {
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

day_zero.config(function ($httpProvider) {
  $httpProvider.interceptors.push('authInterceptor');
});