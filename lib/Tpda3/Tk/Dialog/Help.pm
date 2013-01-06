package Tpda3::Tk::Dialog::Help;

use strict;
use warnings;
use utf8;

use Tk;
use IO::File;

require Tpda3::Tk::TB;
require Tpda3::Config::Utils;

=head1 NAME

Tpda3::Tk::Dialog::Help - Dialog for quick help.

=head1 VERSION

Version 0.62

=cut

our $VERSION = 0.62;

=head1 SYNOPSIS

    use Tpda3::Tk::Dialog::Help;

    my $fd = Tpda3::Tk::Dialog::Help->new;

    $fd->search($self);

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = {
        tb3   => {},    # ToolBar
        tlw   => {},    # TopLevel
        ttext => '',    # text
    };

    return bless( $self, $class );
}

=head2 help_dialog

Define and show search dialog.

=cut

sub help_dialog {
    my ( $self, $view ) = @_;

    $self->{tlw} = $view->Toplevel();
    $self->{tlw}->title('Help');

    # Main frame
    my $tbf0 = $self->{tlw}->Frame();
    $tbf0->pack(
        -side   => 'top',
        -anchor => 'nw',
        -fill   => 'x',
    );

    # Frame for main toolbar
    my $tbf1 = $tbf0->Frame();
    $tbf1->pack( -side => 'left', -anchor => 'w' );

    #-- ToolBar

    $self->{tb3} = $tbf1->TB();

    my $attribs = {
        'tb3gd' => {
            'tooltip' => 'Show User Guide',
            'icon'    => 'appbook16',
            'sep'     => 'none',
            'help'    => 'Show User Guide',
            'method'  => sub { $self->toggle_load('ugd'); },
            'type'    => '_item_check',
            'id'      => '20001',
        },
        'tb3gp' => {
            'tooltip' => 'Show GPL',
            'icon'    => 'appbox16',    # actbookmark16 appbrowser16
            'sep'     => 'after',
            'help'    => 'Show GPL',
            'method' => sub { $self->toggle_load('gpl'); },
            'type'   => '_item_check',
            'id'     => '20002',
        },
        'tb3qt' => {
            'tooltip' => 'Close',
            'icon'    => 'actexit16',
            'sep'     => 'after',
            'help'    => 'Quit',
            'method'  => sub { $self->dlg_exit; },
            'type'    => '_item_normal',
            'id'      => '20003',
        }
    };

    my $toolbars = [ 'tb3gd', 'tb3gp', 'tb3qt', ];

    $self->{tb3}->make_toolbar_buttons( $toolbars, $attribs );

    #-- end ToolBar

    # Frame 1
    my $frame1 = $self->{tlw}->LabFrame(
        -foreground => 'blue',
        -label      => 'Document',
        -labelside  => 'acrosstop'
        )->pack(
        -side => 'bottom',
        -fill => 'both'
        );

    # Text
    $self->{ttext} = $frame1->Scrolled(
        'Text',
        Name        => 'importantText',
        -width      => 70,
        -height     => 30,
        -wrap       => 'word',
        -scrollbars => 'e',
        -background => 'white'
    );

    $self->{ttext}->pack(
        -anchor => 's',
        -padx   => 3,
        -pady   => 3,
        -expand => 's',
        -fill   => 'both'
    );

    # define some fonts.
    my $basefont
        = $self->{ttext}->cget('-font')->Clone( -family => 'Helvetica' );
    my $boldfont = $basefont->Clone( -weight => 'bold', -family => 'Arial' );

    # define a tag for bold font.
    $self->{ttext}->tag( 'configure', 'boldtxt',   -font => $boldfont );
    $self->{ttext}->tag( 'configure', 'normaltxt', -font => $basefont );
    $self->{ttext}->tag(
        'configure', 'centertxt',
        -font    => $boldfont->Clone( -size => 12 ),
        -justify => 'center'
    );

    $self->toggle_load('ugd');

    MainLoop();

    return;
}

=head2 toggle_load

Toggle load.

=cut

sub toggle_load {
    my ( $self, $doc ) = @_;

    if ( $doc eq 'ugd' ) {
        $self->get_toolbar_btn('tb3gd')->select;
        $self->get_toolbar_btn('tb3gp')->deselect;
    }
    elsif ( $doc eq 'gpl' ) {
        $self->get_toolbar_btn('tb3gd')->deselect;
        $self->get_toolbar_btn('tb3gp')->select;
    }
    else {
        return;
    }

    my $proc = "load_${doc}_text";

    $self->$proc;

    return;
}

=head2 get_toolbar_btn

Return toolbar button.

=cut

sub get_toolbar_btn {
    my ( $self, $name ) = @_;

    return $self->{tb3}->get_toolbar_btn($name);
}

=head2 load_gpl_text

Load GPL text.

=cut

sub load_gpl_text {
    my $self = shift;

    my $cfg = Tpda3::Config->instance();

    $self->{ttext}->configure( -state => 'normal' );
    $self->{ttext}->delete( '1.0', 'end' );

    my $txt = Tpda3::Config::Utils->get_license();

    $self->{ttext}->insert( 'end', $txt );

    # not editable.
    $self->{ttext}->configure( -state => 'disabled' );

    return;
}

=head2 load_ugd_text

Load user guide.

=cut

sub load_ugd_text {

    my $self = shift;

    $self->{ttext}->configure( -state => 'normal' );
    $self->{ttext}->delete( '1.0', 'end' );

    my $title = "\n Ghid de utilizare \n\n";

    my $txt = get_help_ro();

    # add the help text.
    $self->{ttext}->insert( 'end', $title, 'centertxt' );
    my $tag = 'normaltxt';

    for my $section ( split( /(<[^>]+>)/, $txt ) ) {
        if ( $section eq '<BOLD>' ) {
            $tag = 'boldtxt';
        }
        elsif ( $section eq '</BOLD>' ) {
            $tag = 'normaltxt';
        }
        else {
            $self->{ttext}->insert( 'end', $section, $tag );
        }
    }

    # not editable.
    $self->{ttext}->configure( -state => 'disabled' );

    return;
}

=head2 dlg_exit

Exit dialog.

=cut

sub dlg_exit {

    my $self = shift;

    $self->{tlw}->destroy;

    return;
}

=head2 get_help_ro

Help text.

=cut

sub get_help_ro {

    my $helptext = qq{

           <BOLD>Introducere</BOLD>

           TPDA (Tiny Perl Database Application) este infrastructura pe care se
           pot clădii rapid și eficient aplicații de baze de date.

           O aplicație este formata dintr-o bază de date cu una sau mai multe
           tabele și câte un Ecran pentru fiecare tabel principal.

           Ecranul este un element grafic de tip fereastră care conține alte
           elemente grafice cum ar fi câmpuri pentru editarea textelor, butoane
           de diverse feluri, tabele, ș.a.m.d.

           Aplicația este formată din două entități distincte, prima este
           sistemul de gestiune al bazei de date (SGBD) care formează partea de
           server și a doua, adică partea de client, aplicația TPDA.

           <BOLD>Înregistrări</BOLD>

           La pornire, după autentificarea utilizatorului, TPDA ne prezintă o
           fereastră cu un meniu și o bară de unelte (butoane).  Primul pas este
           alegerea unui Ecran din meniu, în cazul nostru:

           :     Meniu -> Nume meniu -> Persoane

           În spațiul de sub bara de unelte va apare ecranul pe care utilizatorul
           l-a selectat, încorporat într-o fereastră de tip notebook cu trei
           pagini. Prima pagină este rezervată pentru ecranul principal și
           cuprinde de regulă elemente grafice destinate editării textului din
           câmpurile unui tabel din baza de date.  A doua pagină numită "List",
           cuprinde un tabel utilizat pentru afișarea înregistrărilor găsite după
           o operațiune de căutare. A treia, dacă există, va conține un ecran
           subordonat ecranului principal.

           La start aplicația va intra în stare de așteptare (idle).  În
           funcție de acțiunile utilizatorului, adică de butoanele din bara de
           unelte pe care apasă, aplicația trece dintr-o stare în alta, fiecare
           stare fiind programată pentru o anume acțiune.

           În mod "idle" aplicația așteaptă o acțiune. În acestă stare, în ecran
           nu este afișată nici o înregistrare.

           Din acestă stare, prima acțiune probabilă este comutarea la starea de
           căutare (find) și introducerea unor criterii de căutare, urmată de
           vizualizarea și editarea înregistrărilor găsite.

           <BOLD>Căutare, numărare și editare</BOLD>

           Să presupunem că dorim să căutăm o persoană după cel mai simplu
           criteriu și anume CNP-ul. Apăsăm pe primul buton din bara de unelte,
           acela care are drept simbol o lupă - butonul pentru modul de
           căutare. Aplicația răspunde prin colorarea fondului câmpurilor în
           verde, ceea ce înseamnă că așteaptă introducerea criteriilor de
           căutare (observăm că și în bara de stare a aplicației cuvântul "idle"
           a fost înlocuit cu "find").

           Introducem CNP-ul persoanei a cărei înregistrare dorim să o afișăm, în
           câmpul corespunzător și apăsăm pe butonul al doilea, cel care are ca
           simbol o bifă verde - butonul de execuție a căutării. Dacă în schimb
           utilizatorul apasă pe butonul ce are ca simbol un semn de întrebare,
           atunci în bara de stare va fi afișat numărul de înregistrări care vor
           fi returnate la execuția căutării. Acesta este o facilitate importantă
           a aplicației, pentru că permite numărarea înregistrărilor din baza de
           date după diverse criterii.

           După o operațiune de numărare, starea aplicației nu se schimbă,
           putându-se efectua, în continuare, execuția căutării după criteriile
           deja introduse pentru numărare.

           La căutare sau numărare, TPDA trimite interogarea către baza de date

           :     tpda  ------------------------------->  baza de date

           și primește datele cerute, bineînțeles numai dacă o înregistrare cu
           CNP-ul introdus există în baza de date.

           :     tpda  <------------------------------   baza de date.

           După o căutare reușită, pagina "List" va fi activată automat și în
           tabelul din acestă pagină vor fi inserate principalele date ale
           înregistrării (la configurarea aplicației se pot alege câmpurile care
           vor fi afișate în tabel).

           La activarea Paginii "Record" prin click cu mausul, înregistrarea
           selectată din tabel (implicit ultima) va fi încărcată în ecranul
           aplicației. Putem activa cu mausul pagina "List" ori de câte ori dorim
           și putem alege alte înregistrări din tabel care vor fi încărcate în
           ecranul principal la activarea paginii "Record".

           Dacă nici o înregistrare nu a fost găsită, aplicația va rămâne în
           starea de căutare și va aștepta modificarea criteriilor de căutare sau
           ieșirea din modul căutare, care se poate face prin încă o apăsare pe
           butonul cu lupă. Aplicația va comuta în starea de așteptare.

           <BOLD>Adăugare și editare</BOLD>

           Să presupunem că nu a fost găsită nici o înregistrare care să
           corespundă criteriilor de căutare și aplicația este în stare de
           așteptare (idle). Altă acțiune care poate fi întreprinsă din acestă
           stare este introducerea unei înregistrări noi.

           Pentru acesta apăsăm butonul cu simbolul plus (+) de pe bara de
           unelte, starea aplicației afișată în bara de stare va fi de acum
           adăugare (add).  Completăm datele necesare în câmpurile
           corespunzătoare și apăsăm pe butonul din bara de unelte cu simbolul
           dischetei, pentru a salva datele în baza de date.

           Dacă pentru ecranul curent sunt definite câmpurile care trebuie
           completate obligatoriu înainte de salvarea înregistrării, atunci
           aplicația va verifica dacă nu au rămas câmpuri obligatorii
           necompletate și dacă astfel de câmpuri există, o mică fereastră de
           dialog va informa utilizatorul despre acest lucru, aplicația va rămâne
           în mod adăugare (add). După completarea câmpurilor, la o nouă apăsare
           a butonului de salvare, înregistrarea va fi salvată.

           Salvarea se face prin trimiterea datelor la baza de date

           :     tpda  ------------------------------->  baza de date

           după care TPDA va trece în mod editare, păstrând afișată
           înregistrarea.  În continuare se pot face alte modificări ale datelor
           dace este necesar.

           În modul editare (edit) se pot face adăugiri sau modificări ale
           datelor care vor fi salvate în baza de date la cererea utilizatorului
           prin apăsarea butonului de salvare.

           <BOLD>Ștergere</BOLD>

           Ștergerea unei înregistrări se poate face numai din modul de editare
           (edit). Ca urmare trebuie executată întâi căutarea înregistrării.
           Acesta poate fi ștearsă prin apăsarea butonului cu simbolul (-) minus
           urmată de apăsarea butonului OK din fereastra de dialog pe care o va
           afișa aplicația.

           <BOLD>Important</BOLD>

           <BOLD>ATENȚIE!</BOLD> Nu există nici un alt mijloc de a recupera o
           înregistrare ștearsă în afara restaurării copiei de siguranță a bazei
           de date.
};

    return $helptext;
}

1;
