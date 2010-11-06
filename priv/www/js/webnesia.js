function render_table(limit, offset)
{
    var table = window.location.href.slice(window.location.href.indexOf("?") + 1);
    $.get("/" + table, function(tableInfo) {
        $("#table_caption").html($("#table_caption_tmpl").tmpl(tableInfo.table_name));
        $("#table_header").html($("#table_header_tmpl").tmpl(tableInfo.attributes));
        $.get("/" + table + "/_all_records?limit=" + limit + "&skip=" + offset, function(data) {
            data.number_of_attributes = tableInfo.number_of_attributes;
            $("#table_footer").html($("#table_footer_tmpl").tmpl(data));
            data = data.rows;
            for (key in data) {
                data[key].keys = tableInfo.attributes;
            }
            $("#table_body").html($("#table_body_tmpl").tmpl(data));
        });
    });
}

function create_test_table () {
    $.ajax({url: "/test", type: "PUT", async: false, data: JSON.stringify(["id", "timestamp", "test_field"]), success: function (data) {
        if (data == "ok") {
            for (var i = 0; i < 100 ; i++) {
                $.ajax({url: "/test", type: "POST", async: false, data: JSON.stringify({"id": i, "test_field_1": new Date().getTime(), "test_field": "the brown fox jumps over the lazy dog"})});
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