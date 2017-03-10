{application, chatServer, 
[{description, "a simple chat server"},
 {vsn,"0.1.0"},
 {modules, [
 			cs_app,
 			cs_sup
 			]},
 {registered, [cs_sup]},
 {applications, [kernel, stdlib]},
 {mod, {cs_app, []}}
 ]}.