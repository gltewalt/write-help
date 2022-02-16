Red [
    Author: "Greg Tewalt"
    File:    %write-help.red
    Tabs: {
        Captains Log 02-15-2022

        This is old, so it takes me a bit to work through what
        the code is doing too. Needs a revision and updating, but it works
        as is.
    }
]


comment [
    TODO: Delete write-help and write-summary if --all of function! is chosen. 
    They end up being written into the functions folder.
]

;-- To compile:  #include %/<your-path-to>/help.red       ;

usage: [    ;-- action! markdown
    "Usage:" crlf "./help-writer <function type!> <template>" newline 
    "./help-writer -a , --all <template>"
]

args: system/script/args    ; to parse one string for command-line options like "--all asciidoc"
options: to block! trim/with args #"'"  ; system/option/args is a block of strings - want words
valid-function-types: [action! function! native! op! routine!]

options-rule:       ["-a" | "--all"]
template-rule:      ["asciidoc" | "markdown" | "latex" | "html"] 
function-name-rule: ["action!" | "function!" | "native!" | "op!" | "routine!"]
pluralize:          [some [change #"!" #"s" | skip]]

; begin templates 
; global variables for now in summary templates... :-/
; --------------------------------------------------------------------------------------------------------------------------
asciidoc: ["===" space n crlf "[source, red]" crlf "----" crlf help-string (to-word :n) crlf "----"]
summary-asciidoc: ["===" space header space "values" crlf crlf output crlf]

markdown: ["###" space n crlf "```red" crlf help-string (to-word :n) crlf "```"]
summary-markdown: ["###" space header space "values" crlf crlf output crlf]

html: [{
    <!DOCTYPE html><html lang="en"><head>
    <meta charset="UTF-8"><title>} n {</title>
    <style>
    h2 {font-family:"Times New Roman",times;font-weight:400;font-style:normal;color:#ba3925;}   
    .content {border: 1px dotted black;padding-top: 15px;padding-bottom: 15px;padding-left: 40px;background-color: #ffffcc;}
    .header {padding-top: 15px;padding-bottom: 15px;padding-right: 150px;padding-left: 150px;}
    pre {color:rgba(0,0,0,.9); font-family:"Times New Roman";line-height:1.45;text-rendering:optimizeLegibility;}
    code {font-family:"Times New Roman";font-weight:400;color:rgba(0,0,0,.9);}
    </style>
    </head>
    <div class="header"><body><h2 id="">} n {</h2>
    <div class="content"><pre><code><pre>} help-string (to-word :n) {</code></pre></div></div></body></html>}
]

summary-html: [{
    <!DOCTYPE html><html lang="en"><head>
    <meta charset="UTF-8"><title>} title {</title>
    <style>
    h2 {font-family:"Times New Roman",times;font-weight:400;font-style:normal;color:#ba3925;}   
    .content {border: 1px dotted black;padding-top: 15px;padding-bottom: 15px;padding-left: 40px;background-color: #ffffcc;}
    .header {padding-top: 15px;padding-bottom: 15px;padding-right: 150px;padding-left: 150px;}
    pre {color:rgba(0,0,0,.9); font-family:"Times New Roman";line-height:1.45;text-rendering:optimizeLegibility;}
    code {font-family:"Times New Roman";font-weight:400;color:rgba(0,0,0,.9);}
    </style>
    </head>
    <div class="header">
    <body><body><h2 id="">} header { values</h2>
    <div class="content"><pre><code><pre>} output {</code></pre></div></div>
    </body>
    </html>}
]
; ------------------------------------------------------------------------------------------------------------------------

gather-function-names: func [txt] [
    function-names: copy []
    ws: charset reduce [space tab cr lf]
    rule: [s: collect into function-names any [ahead [any ws "=>" e:] b: keep (copy/part s b) :e | ws s: | skip]] ; rule by toomasv
    parse txt rule  ; grab all function names and put them in function-names block to loop through
]

make-dir-name: func [w [word!] parse-rule [block!] /local o][
    o: mold w
    parse o parse-rule
    dest: make-dir to-file rejoin [o '- options/2]
]

write-help: func [template [block!] /local ext][
    ext: case [
        template = asciidoc ['.adoc]
        template = html     ['.html]
        template = markdown ['.md]
    ]
    foreach n function-names [
        f: copy n
        parse f [some [change #"?" "_question_" | change #"*" "_asterisk_" | skip]]  
        either f = "is" [continue][write to-file rejoin [dest f ext] rejoin compose template]  ; can't write 'is' to file
    ]
]

write-summary: func [func-type [word!] template [block!] /local ext][
        ext: case [
            template = asciidoc ['.adoc]
            template = html     ['.html]
            template = markdown ['.md]
        ]
        output: copy ""
        title: header: form func-type  
        foreach n sort function-names [
            f: copy n
            parse f [some [change #"?" "_question_" | change #"*" "_asterisk_" | skip]]  
            append output rejoin case [
                template = asciidoc [[{link:./} f ext {[} n {]} crlf crlf]]
                template = markdown [[{[} n {](} f ext {)} crlf crlf]]
                template = html     [[{<a href="./} f ext {">} n {</a><br>}]]
            ]
        ]
        write to-file replace rejoin [dest func-type "summary" ext] "!" "s-" rejoin compose case [
            template = asciidoc [summary-asciidoc]
            template = markdown [summary-markdown]
            template = html     [summary-html]
        ]
]

do-all: does [
    foreach type-name valid-function-types [
        make-dir-name type-name pluralize
        gather-function-names help-string :type-name
        write-summary type-name reduce options/2
        write-help reduce options/2
    ]
]

do-one: does [
    make-dir-name options/1 pluralize
    gather-function-names help-string :options/1 
    write-summary options/1 reduce options/2
    write-help reduce options/2
]

main: does [
    unless parse args [
        any options-rule skip some template-rule (do-all) 
        | some function-name-rule skip some template-rule (do-one)
    ][print usage]
]

main
