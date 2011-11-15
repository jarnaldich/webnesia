var activity = false;


function decode_bert(bert) {
  var view = new jDataView(bert);
  var bytes = new Array(view.length);
  
  for(var i = 0; i < view.length; i++)
    bytes[i] = view.getUint8(i);
  
  return Bert.decode(Bert.bytes_to_string(bytes));
}

function decode_bert_dict(bert)
{
  tableInfo = {};
  decode_bert(bert)[0][2].forEach(function(x) {
    tableInfo[x[0][0].value] = x[0][1];
  });
  return tableInfo;
}

function render_table(limit, offset)
{
  activity = true;
  show_activity();
  var table = window.location.href.slice(window.location.href.indexOf("?") + 1);
  $.get("/" + table, function(bert) {
    var tableInfo = decode_bert_dict(bert);

    $("#table_caption").html($("#table_caption_tmpl").tmpl(tableInfo.table_name));
    $("#table_header").html($("#table_header_tmpl").tmpl(tableInfo.attributes));
    $.get("/" + table + "/_all_records?limit=" + limit + "&skip=" + offset, 
          function(bert2) {
            data = decode_bert_dict(bert2);
            data.number_of_attributes = tableInfo.number_of_attributes;
            var new_rows = data.rows.map(function(x) {
              var r = {}; 
              x[0][2].forEach(function(h) { 
                r[h[0][0]] = h[0][1].toString();
              });
              
              return r;
            });

            data.rows = new_rows
            var keys = tableInfo['attributes'].reduce(function(acum, x) { 
              acum.push(x.value);
              return acum;
            }, []);

            $("#table_footer").html($("#table_footer_tmpl").tmpl(data));
            data = data.rows;
            for (key in data) {
              data[key].keys = keys;
              data[key].table = table;
            }

            $("#table_body").html($("#table_body_tmpl").tmpl(data));
            activity = false;
            hide_activity();},
          'binary');
  }, 
        'binary');
}

function render_record()
{
  activity = true;
  show_activity();
  var table_record = window.location.href.slice(window.location.href.indexOf("?") + 1).split(/\//);
  var table = table_record[0];
  var record = table_record[1];
  console.log(table);
  $.get("/" + table, function(bert) {
    var tableInfo = decode_bert_dict(bert);
    console.log(tableInfo);

    $("#table_caption").html($("#table_caption_tmpl").tmpl({"table": tableInfo.table_name, "record": record}));
    $.get("/" + table + "/" + record, function(bert2) {
      $("#table_body").html($("#table_body_tmpl").tmpl(data.rows[0]));
      activity = false;
      hide_activity();
    }, 
          'binary');
  }, 
        'binary');
}

function create_test_table () {
    $.ajax({url: "/test", 
            type: "PUT", async: false,
            dataType: "binary",
            data: Bert.encode(["id", "timestamp", "test_field"]), success: function (data) {
      data = decode_bert(data);
      if (data == "ok") {
        for (var i = 1; i <= 50 ; i++) {
          $.ajax({url: "/test", 
                  type: "POST", 
                  dataType: 'binary',
                  async: false, 
                  data: Bert.encode({id: i, 
                                     timestamp: i, 
                                     test_field: Bert.binary("the brown fox jumps over the lazy dog")})});
        }
        location.reload();
      }
    }});
}

function delete_test_table () {
    $.ajax({url: "/test", type: "DELETE", async: false, success: function (data) {
        location.reload();
    }});   
}

function show_activity () {
    $("#activity_indicator").fadeIn(125, function () {
        if (activity) {
            hide_activity();
        }
    });
}

function hide_activity () {
    $("#activity_indicator").fadeOut(125, function () {
        if (activity) {
            show_activity();
        }
    });
}
