#! /usr/local/bin/wish8.0

# Len system emulator v1.01 By Uri Shaked <uri@keves.org>
# Copyright and license:
# * Any modifications or patches should be sent to the author (uri@keves.org).
# * You can freely redistribute this software as long as my comments and the
#  entire documentation stick with it.
# * This program is distributed for educational purposes only and without
#  explicit or implicit warranty; in no event shall the author or contributors
#  be liable for any direct, indirect or incidental damages arising in any way
#  out of the use of this software.
set version 1.01

proc create_len {lenid f hcenter vcenter {redraw 1}} {
    global lens
    set lens($lenid,f) $f
    set lens($lenid,hcenter) $hcenter
    set lens($lenid,vcenter) $vcenter
    .c create line $hcenter 0 $hcenter [winfo height .c] -width 4 -fill yellow -arrow both -arrowshape {3 10 7} -tags "len$lenid lens clickable len$lenid:all lens"
    .c create line 0 0 0 0 -fill cyan -width 2 -tags "len$lenid:focus len$lenid:f1 focus clickable len$lenid:all lens"
    .c create line 0 0 0 0 -fill cyan -width 2 -tags "len$lenid:focus len$lenid:f2 focus clickable len$lenid:all lens"
    #create IMG/LINE1..3 lines
    .c create line 0 0 0 0 -fill #0098c6 -width 2 -arrowshape {7 10 6} -arrow last -tags "len$lenid:image len$lenid:all lens"
    .c create line 0 0 0 0 -fill white -width 2 -tags "len$lenid:line1 len$lenid:all lens"
    .c create line 0 0 0 0 -fill white -width 2 -tags "len$lenid:line2 len$lenid:all lens"
    .c create line 0 0 0 0 -fill white -width 2 -tags "len$lenid:line3 len$lenid:all lens"
    .c bind len$lenid:focus <B1-Motion> "move_focus $lenid %x %y"
    .c bind len$lenid <B1-Motion> "move_len $lenid %x %y"
    .c bind len$lenid <3> "delete_len $lenid"
    .c raise object
    draw_len_focus $lenid
    if {$redraw} {
	draw_len_system
    }
}

proc delete_len {lenid} {
    global lens
    foreach i [array names lens $lenid,*] {
	unset lens($i)
    }
    .c delete len$lenid:all
}

proc load_len_info {lenid} {
    global lens
    foreach i [array names lens $lenid,*] {
	set v [join [lrange [split $i ,] 1 end] ,]
	catch {upvar $v $v}
	set $v $lens($i)
    }
}

proc draw_object {} {
    global object vcenter
    .c coords object $object(left) $vcenter $object(left) [expr $vcenter - $object(height)]
}

proc draw_len_focus {lenid} {
    load_len_info $lenid
    .c coords len$lenid:f1 [expr $hcenter + $f] [expr $vcenter - 10] [expr $hcenter + $f] [expr $vcenter + 10]
    .c coords len$lenid:f2 [expr $hcenter - $f] [expr $vcenter - 10] [expr $hcenter - $f] [expr $vcenter + 10]
}

proc draw_len {lenid objh u} {
    global lens
    load_len_info $lenid
    #get v/img height
    if {$f == 0} {
	set f 0.0000001
    }
    if {$u == 0} {
	set u 0.0000001
    }
    if {abs($u) == $f} {
	set u [expr $u + 0.0000001]
    }
    set v [expr 1.0/(1.0/$f - 1.0/abs($u))]
    if {$u < 0} {
	set v [expr -$v]
    }
    set imgh [expr $objh * $v / $u]
    #draw image
    .c coords len$lenid:image [expr $hcenter - $v] $vcenter [expr $hcenter - $v] [expr $vcenter + $imgh]
    #draw lines
    .c coords len$lenid:line1 [expr $hcenter + $u] [expr $vcenter - $objh] [expr $hcenter - $v] [expr $vcenter + $imgh]
    .c coords len$lenid:line2 [expr $hcenter + $u] [expr $vcenter - $objh] $hcenter [expr $vcenter - $objh] [expr $hcenter - $v] [expr $vcenter + $imgh]
    .c coords len$lenid:line3 [expr $hcenter + $u] [expr $vcenter - $objh] $hcenter [expr $vcenter + $imgh] [expr $hcenter - $v] [expr $vcenter + $imgh]
    set lens($lenid,imgh) [expr -$imgh]
    set lens($lenid,v) [expr -$v]
}

proc draw_len_system {} {
    global object lens
    
    # order lens by distance
    set lenlist ""
    foreach i [array names lens *,hcenter] {
	set n [lindex [split $i ,] 0]
	lappend lenlist [list $lens($i) $n]
    }
    set sorted [lsort -real -index 0 $lenlist]
    
    # search for the lens the object resides between.
    # binary search will probably be better here.
    set cnt 0
    set leftlen -1
    foreach i $sorted {
	if {[lindex $i 0] >= $object(left)} {
	    set leftlen $cnt
	    break
	}
	incr cnt
    }
    if {$leftlen == -1} {
	set leftlen [llength $sorted]
    }
    
    # draw lens
    set objl $object(left)
    set objh $object(height)
    for {set i [expr $leftlen - 1]} {$i >= 0} {incr i -1} {
	set len [lindex [lindex $sorted $i] 1]
	draw_len $len $objh [expr $objl - $lens($len,hcenter)]
	set objh $lens($len,imgh)
	set objl [expr $lens($len,hcenter) + $lens($len,v)]
    }
    set objl $object(left)
    set objh $object(height)
    for {set i $leftlen} {$i < [llength $sorted]} {incr i} {
	set len [lindex [lindex $sorted $i] 1]
	draw_len $len $objh [expr $objl - $lens($len,hcenter)]
	set objh $lens($len,imgh)
	set objl [expr $lens($len,hcenter) + $lens($len,v)]
    }
}

proc save_lens {file} {
    global version lens object vcenter
    set fd [open $file w]
    puts $fd [format {; Len System Information File, version %s
; Created by Len System Emulator version %s by Uri Shaked <uri@keves.org>,
; icq#13406762.
} $version $version]
    puts $fd "LENSYSTEM"
    puts $fd "VERSION 1.0"
    puts $fd "VERTICAL $vcenter [.c itemcget vertical -fill]"
    puts $fd "OBJECT $object(left) $object(height) [.c itemcget object -fill]"
    puts $fd "WINDOW [winfo width .] [winfo height .]"
    foreach i [array names lens *,f] {
	set i [lindex [split $i ,] 0]
	load_len_info $i
	set lenclr [.c itemcget len$i -fill]
	set imgclr [.c itemcget len$i:image -fill]
	set ln1clr [.c itemcget len$i:line1 -fill]
	set ln2clr [.c itemcget len$i:line2 -fill]
	set ln3clr [.c itemcget len$i:line3 -fill]
	puts $fd "LEN $hcenter $vcenter $f $imgclr $ln1clr $ln2clr $ln3clr"
    }
    puts $fd "EOF"
    close $fd
}

proc load_int {lineno line argn} {
    set n [lindex $line $argn]
    if [catch {expr int($n)}] {
	error "(line $lineno) argument #$argn for command '[lindex $line 0]' is Invalid: expected integer."
    }
    return $n
}

proc load_color {lineno line argn} {
    set c [lindex $line $argn]
    if [catch {.c create line -1 -1 -1 -1 -tags temp -fill $c} err] {
	error "(line $lineno) argument #$argn for command '[lindex $line 0]' is Invalid: expected color name."
    }
    .c delete temp
    return $c
}

proc load_lens {file} {
    global lens lastlen object vcenter
    set fd [open $file r]
    set start 0
    set lineno 0
    while {![eof $fd]} {
	set line [split [string trim [gets $fd]]]
	incr lineno
	if [string match {;#$} [string index $line 0]] {
	    continue
	}
	set cmd [string toupper [lindex $line 0]]
	set args [lrange $line 1 end]
	if {!$start} {
	    if {$cmd == "LENSYSTEM"} {
		set start 1
	    }
	    continue
	}
	switch -exact $cmd {
	    VERSION {
		set args [join $args]
		if {$args != 1.0} {
		    error "Incorrect file version $args"
		}
	    }
	    OBJECT {
		set objl [load_int $lineno $line 1]
		set objh [load_int $lineno $line 2]
		set objc [load_color $lineno $line 3]
	    }
	    VERTICAL {
		set _vcenter [load_int $lineno $line 1]
		set vcolor [load_color $lineno $line 2]
	    }
	    WINDOW {
		set winw [load_int $lineno $line 1]
		set winh [load_int $lineno $line 2]
	    }
	    LEN {
		lappend lenlist [load_int $lineno $line 1] \
				[load_int $lineno $line 2] \
				[load_int $lineno $line 3] \
				[load_color $lineno $line 4] \
				[load_color $lineno $line 5] \
				[load_color $lineno $line 6] \
				[load_color $lineno $line 7]
	    }
	    EOF {
		break
	    }
	}
    }
    if {!$start} {
	error "No len system information was found in the given file."
    }
    close $fd
    unset lens
    .c delete lens
    set lastlen 1
    if [info exists winw] {
	set pos [lindex [split [wm geometry .] +] 1]
	wm geometry . =${winw}x${winh}
    }
    foreach {h v f imgclr ln1clr ln2clr ln3clr} $lenlist {
	create_len $lastlen $f $h $v 0
	.c itemconfigure len$lastlen:image -fill $imgclr
	.c itemconfigure len$lastlen:line1 -fill $ln1clr
	.c itemconfigure len$lastlen:line2 -fill $ln2clr
	.c itemconfigure len$lastlen:line3 -fill $ln3clr
	incr lastlen
    }
    if [info exists objh] {
	set object(left) $objl
        set object(height) $objh
	.c itemconfigure object -fill $objc
	draw_object
    }
    if [info exists _vcenter] {
	set vcenter $_vcenter
	.c itemconfigure vertical -fill $vcolor
    }
    # redraw the len system
    draw_len_system
}

proc click_object {x y} {
    global move
    set move(x) $x
    set move(y) $y
}

proc move_object {x y} {
    global move lens object
    set object(left) [expr $object(left) + ($x - $move(x))]
    set object(height) [expr $object(height) - ($y - $move(y))]
    set move(x) $x
    set move(y) $y
    draw_object
    draw_len_system
}

proc color_object {} {
    global oldcolor
    set shape [.c find withtag current]
    set newcolor [tk_chooseColor -parent . -initialcolor [.c itemcget $shape -fill] -title "Choose a new color"]
    if {$newcolor == ""} {
	return
    }
    .c itemconfigure $shape -fill $newcolor
    set oldcolor $newcolor
}

proc move_focus {lenid x y} {
    global move lens
    set lens($lenid,f) [expr $lens($lenid,f) + ($x - $move(x))]
    if {$lens($lenid,f) < 0} {
	.c itemconfigure len$lenid -arrowshape {8 0 7}
    } else {
	.c itemconfigure len$lenid -arrowshape {3 10 7}
    }
    set move(x) $x
    draw_len_focus $lenid
    draw_len_system
}

proc move_len {lenid x y} {
    global move lens
    set lens($lenid,hcenter) [expr $lens($lenid,hcenter) + ($x - $move(x))]
    set move(x) $x
    .c coords len$lenid $lens($lenid,hcenter) 0 $lens($lenid,hcenter) [winfo height .c]
    draw_len_focus $lenid
    draw_len_system
}

proc delete_len {lenid} {
    global lens
    .c delete len$lenid:all
    foreach i [array names lens $lenid,*] {
	unset lens($i)
    }
    draw_len_system
}

proc create_new_len {} {
    global lens lastlen vcenter
    set lens($lastlen,next) [incr lastlen]
    create_len $lastlen 15 150 $vcenter
}

proc load_len_system {} {
    set fname [tk_getOpenFile -defaultextension *.ls -title "Load a len system" -filetypes [list {"Len Systems" *.ls}]]
    if {$fname == ""} {
	return
    }
    if [catch {
	load_lens $fname
    } err] {
	tk_dialog .error_dlg "Error Loading File" "The following error had occured while reading the file: $err" error 0 "Dismiss"
    }    
}

proc save_len_system {} {
    set fname [tk_getSaveFile -defaultextension *.ls -title "Save a len system" -filetypes [list {"Len Systems" *.ls}]]
    if {$fname == ""} {
	return
    }
    if [catch {
	save_lens $fname
    } err] {
	tk_dialog .error_dlg "Error Saving File" "The following error had occured while saving the file: $err" error 0 "Dismiss"
    }
}

proc check_resize {} {
    global old_height lens
    if {$old_height != [winfo height .c]} {
	set old_height [winfo height .c]
	foreach i [array names lens *,hcenter] {
	    .c coords len[lindex [split $i ,] 0] $lens($i) 0 $lens($i) $old_height
	}
    }
    after 1000 check_resize
}

proc show_help {} {
    global version
    tk_dialog .help_dlg "Help" "Len System emulator v$version by Uri Shaked <uri@keves.org>, ICQ#13406762\n---\nHelp:\nYou can move/resize the lens, the focus, and the object.\nTo change the color of something, double click on it.\nTo delete a len, click on it with the right button of mouse." "" 0 "Dismiss"
}

set len(f) 25
set len(center) 160
set object(left) 225
set object(height) 50
set vcenter 120

wm title . "Len System Emulator"
canvas .c -background black -height 240 -width 320
frame .f
button .f.add -command "create_new_len" -text "Create len !"
button .f.save -command "save_len_system" -text "Save"
button .f.load -command "load_len_system" -text "Load"
button .f.help -command "show_help" -text "Help"
label .copyright -text "Copyright (C) 2001, Uri Shaked <uri@keves.org>"
pack .c -fill both -expand 1
pack .f
pack .f.add -side left
pack .f.save -side left
pack .f.load -side left
pack .f.help -side left
pack .copyright -fill both
# create the vertical
.c create line 0 $vcenter 2048 $vcenter -width 4 -fill yellow -tags vertical
# create and draw the object
.c create line 0 0 0 0 -fill red -width 2 -arrowshape {7 10 6} -arrow last -tags "object clickable"
draw_object
# create the first len
after 200 {
    create_len 1 $len(f) $len(center) $vcenter
    set lastlen 1
}
# general bindings
.c bind object <B1-Motion> "move_object %x %y"
.c bind object <Enter> {
    set oldcolor [.c itemcget current -fill]
    .c itemconfigure current -fill purple
}
.c bind object <Leave> {.c itemconfigure current -fill $oldcolor}
.c bind focus <Enter> {
    set oldcolor [.c itemcget current -fill]
    .c itemconfigure current -fill purple
}
.c bind focus <Leave> {.c itemconfigure current -fill $oldcolor}
.c bind clickable <1> "click_object %x %y"
.c bind all <Double-1> "color_object"
# initialize resize-detect system
set old_height -1
check_resize
