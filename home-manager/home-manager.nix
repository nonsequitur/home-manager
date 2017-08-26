{ pkgs ? import <nixpkgs> {}
, confPath
, confAttr
, check ? true
, newsSince ? "1970-01-01T00:00:00+00:00"
}:

with pkgs.lib;

let

  env = import <home-manager> {
    configuration =
      let
        conf = import confPath;
      in
        if confAttr == "" then conf else conf.${confAttr};
    pkgs = pkgs;
    check = check;
  };

  newsFiltered =
    let
      pred = entry: entry.condition && entry.time > newsSince;
    in
      filter pred env.newsEntries;

  newsNumUnread = length newsFiltered;

  newsLatestEntryTime =
    if env.newsEntries == []
    then "1970-01-01T00:00:00+00:00"
    else (head env.newsEntries).time;

  newsFileUnread = pkgs.writeText "news-unread.txt" (
    concatMapStringsSep "\n\n" (entry:
      let
        time = replaceStrings ["T"] [" "] (removeSuffix "+00:00" entry.time);
      in
        ''
          * ${time}

            ${replaceStrings ["\n"] ["\n  "] entry.message}
        ''
    ) newsFiltered
  );

  newsFileAll = pkgs.writeText "news-all.txt" (
    concatMapStringsSep "\n\n" (entry:
      let
        flag = if entry.time > newsSince then "unread" else "read";
        time = replaceStrings ["T"] [" "] (removeSuffix "+00:00" entry.time);
      in
        ''
          * ${time} [${flag}]

            ${replaceStrings ["\n"] ["\n  "] entry.message}
        ''
    ) env.newsEntries
  );

  newsInfo = pkgs.writeText "news-info.sh" ''
    local newsNumUnread=${toString newsNumUnread}
    local newsDisplay="${env.newsDisplay}"
    local newsLatestEntryTime="${newsLatestEntryTime}"
    local newsFileAll="${newsFileAll}"
    local newsFileUnread="${newsFileUnread}"
  '';

in
  {
    inherit (env) activationPackage;
    inherit newsInfo;
  }
