backend app_1 {
    .host = "10.100.11.25";
    .port = "80";
    .connect_timeout = 60s;
    .first_byte_timeout = 60s;
    .between_bytes_timeout = 60s;
    #  .probe = {
    #    .url = "/user";
    #    .interval = 10s;
    #    .timeout = 6s;
    #    .window = 5;
    #    .threshold = 3;
    #  }
}

backend app_2 {
    .host = "10.100.11.37";
    .port = "80";
    .connect_timeout = 60s;
    .first_byte_timeout = 60s;
    .between_bytes_timeout = 60s;
    #  .probe = {
    #    .url = "/user";
    #    .interval = 10s;
    #    .timeout = 6s;
    #    .window = 5;
    #    .threshold = 3;
    #  }
}

director default_director round-robin {
    { .backend = app_1; }
    { .backend = app_2; }
}
