var Radio = {
  ALBUM_API_URL : "http://ws.audioscrobbler.com/2.0/" +
                  "?method=album.getinfo&api_key=cc842aec7834dde91ae2bc46f5d1a570&format=json&",

  ITEM_ELEMENT : $('<li>' +
                     '<span class="duration" />' +
                     '<img />' +
                     '<span class="song" />' +
                     '<span class="artist" /><span class="album" />' +
                   '</li>'),

  initialize: function() {
    this.socket = new WebSocket("ws://localhost:8080");

    this.createElements();
    this.bindEventListeners();
  },

  addSong: function(data) {
    var item      = this.ITEM_ELEMENT.clone(),
        remaining = data.duration - (data.position || 0);

    item
      .find(".song").text(data.title).end()
      .find(".artist").text("by " + data.artist).end()
      .find(".album").text(" on " + data.album).end()
      .find(".duration").data("duration", data.duration).end()
      .addClass("active")
      .prependTo("ul");

    $("li").eq(7).remove();

    this.setDuration(remaining, item);
    this.loadImage(data);
  },

  bindEventListeners: function() {
    $(document).on("keypress", $.proxy(this.onKeyPress, this));

    $(this.socket)
      .on("close", $.proxy(this.onClose, this))
      .on("message", $.proxy(this.onMessage, this));
  },

  createElements: function() {
    $("<ul>").appendTo("body");
  },

  loadImage: function(data) {
    var artist  = $.trim(data.artist.replace(/\([^)]+\)/g, "")),
        album   = $.trim(data.album.replace(/\([^)]+\)/g, "")),
        options = $.param({ artist: artist, album: album });

    $.getJSON(this.ALBUM_API_URL + options, function(data) {
      if (!data.album) {
        return;
      }

      var url = $.trim(data.album.image[2]["#text"] || "");

      if (!url) {
        url = "/images/no-album.png";
      }

      $(".active img").attr("src", url).fadeIn();
    });
  },

  reset: function() {
    var item = $(".active");

    if (item.length == 1) {
      this.setDuration(item.find(".duration").data("duration"));
      item.removeClass("active");
    }
  },

  setDuration: function(duration, element) {
    var element = element || $(".active"),
        minutes = Math.floor(duration / 60),
        seconds = duration % 60,
        seconds = seconds < 10 ? "0" + seconds : seconds;

    if (element.find(".duration").length == 1) {
      element = element.find(".duration");
    }

    element.text([minutes, seconds].join(":"));
  },

  onClose: function() {
    var item = this.ITEM_ELEMENT.clone();

    item
      .addClass("active")
      .find(".song")
        .text("Disconnected")
      .end()

    $("ul")
      .empty()
      .append(item);
  },

  onKeyPress: function(event) {
    switch (event.which) {
      case 32: // Space
        this.socket.send("toggle");
      break;

      case 78:  // n
      case 110: // N
        this.reset();
        this.socket.send("next");
      break;
    }

    return false;
  },

  onMessage: function(event) {
    var event = event.originalEvent,
        data  = $.parseJSON(event.data);

    if (data.event == "position") {
      var remaining = $(".active .duration").data("duration") - data.position;

      this.setDuration(remaining);
    } else if (data.event == "reset") {
      this.reset();
    } else {
      this.reset();
      this.addSong(data);
    }
  }
};

$($.proxy(Radio.initialize, Radio));
