{application, cache_gen_server,
 [{description, "An OTP application"},
  {vsn, "0.1.0"},
  {registered, [cache_gen_server_sup]},
  {mod, {cache_gen_server_app, []}},
  {applications,
   [kernel,
    stdlib
   ]},
  {env,[]},
  {modules, [cache_gen_server, cache_gen_server_app, cache_gen_server_sup]},

  {licenses, ["Apache 2.0"]},
  {links, []}
 ]}.
