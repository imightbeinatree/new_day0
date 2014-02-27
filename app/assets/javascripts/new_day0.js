$("#new_user").bind("ajax:success", function(event, data, status, xhr){
   alert("here is the sign up return\n"+data);
}).bind("ajax:error", function(event, data, status, xhr){
   alert("error, here is the sign up error return\n"+data);  
});