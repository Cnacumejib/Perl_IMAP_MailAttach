#!/usr/bin/perl
# mailattach.pl
 
  use strict;
  use warnings;
  use Net::IMAP::Simple;
  use Mail::Header;
#  use POSIX qw(strftime);
  use POSIX;


# параметры почтового ящика
  my $mailhost = "mymailserver.mir";
  my $mailuser = 'myuser@mymailserver.mir';
  my $mailpass = 'mypassword';
  my $mailfolder = "INBOX";                           # папка, в которой проверяем почту

  my $maindir="/NetAccess/MailBox/Attaches/";
  my $dir="$maindir/$mailuser";
  my $filename = "$dir/check_mail";

  unless (-d $dir) {system ("mkdir $dir");}
  $0=~/^(.+[\\\/])[^\\\/]+[\\\/]*$/;
  chdir $maindir;

  my $imap = Net::IMAP::Simple->new(                  # создаем подключение к серверу
        $mailhost,
        port    => 993,
        use_ssl => 1,
        debug => 0,
        ) || die "Unable to connect to IMAP: $Net::IMAP::Simple::errstr\n";
 
  if(!$imap->login($mailuser,$mailpass)){
    print STDERR "Login failed: " . $imap->errstr . "\n";
    exit(64);
  }


  my $nm = $imap->select($mailfolder);                # Считываем количество входящих сообщений

  if (open(my $fh, '<:encoding(UTF-8)', $filename)) { # Считываем количество обработанных ранее сообщений
  	$ns = <$fh>;
		close($fh);
  } else {
		$ns=$nm-100;
		print "\n\nCould not open file '$filename' $!\n\n";
  }
  open my $fh, "> $filename";                         # Записываем количество обрабатываемых сообщений
  print $fh "$nm";
  close($fh);


for(my $i = $ns; $i <=$nm ; $i++){                    # Последовательно проходим по списку сообщений   
    my $header = $imap->top($i);                      # Получаем список служебных заголовков письма    
    my $head_obj = Mail::Header->new($header);        # Разбиваем заголовки на отдельные составляющие  
    my $mydate = $head_obj->get('Date');              # по дате письма формируем имя директории для сохранения вложений
    my @arrdate =split(" ",$mydate);
    if (isdigit($arrdate[1])){ 
   	  my $day=$arrdate[1]+0;
   	  $mydate ="$arrdate[3]_$arrdate[2]_$day";}
    else{
	    my $day=$arrdate[0]+0;
   	  $mydate ="$arrdate[2]_$arrdate[1]_$day";
    }

    open MSGFILE,"> $dir/msg"                                         # Сохраняем текущее собщение в файл msg
      or die "Couldn't open file: Attaches/msg\n";    
    print MSGFILE @{ $imap->get($i) };
    close MSGFILE;
    system ("/usr/local/bin/ripmime","-i$dir/msg","-d$dir/$mydate");  # разбираем письмо на вложения  
    system ("/bin/rm -rf $dir/$mydate/textfile*");                    # удаляем текстовые файлы 

}

system ("find . -empty -type d -delete");                             # удаляем пустые папки
system ("convmv -r --notest -f koi8-r -t utf8 $dir");                 # меняем кодировку файлов  
system ("chown -R nobody:nogroup $dir");                              # меняем владельца для доступа по сети

$imap->quit;                                                          # Закрываем подключение к imap серверу

exit 0;
