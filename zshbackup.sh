#!/usr/bin/env bash

set -u

printf '\n🛡️ ZSHBACKUP • PORTABLE RECOVERY\n'
printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'

if ! command -v perl >/dev/null 2>&1; then
    printf '❌ Perl is required. Install it with: pkg install perl\n'
    exit 1
fi

DEFAULT_ROOT="/sdcard/Download/termux-outputs/ZSH_BACKUP"

printf '\n📍 BACKUP LOCATION\n'
printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
printf 'Default location:\n%s\n\n' "$DEFAULT_ROOT"
while true; do
    printf '\n'
    printf '📍 DIRECTORY STATUS\n'
    printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'

    if [[ -d "$DEFAULT_ROOT" ]]; then
        printf 'Default directory: DIR ✅\n'
    else
        printf 'Default directory: DIR MISSING\n'
    fi

    printf '\n'
    if [[ -d "$DEFAULT_ROOT" ]]; then
        printf '  1. 📂 Use existing directory\n'
    fi
    printf '  2. ➕ Create / verify default directory\n'
    printf '  3. 📍 Enter custom directory\n'
    printf '  0. 🚪 Exit\n'
    printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    printf 'Select an option: '

    IFS= read -r choice || exit 0

    case "$choice" in
        1)
            if [[ -d "$DEFAULT_ROOT" ]]; then
                BACKUP_ROOT="$DEFAULT_ROOT"
                break
            fi
            printf '\n⚠️ Default directory is missing.\n'
            ;;

        2)
            if mkdir -p -- "$DEFAULT_ROOT" && [[ -d "$DEFAULT_ROOT" ]]; then
                BACKUP_ROOT="$DEFAULT_ROOT"
                printf '\n✅ Default directory ready.\n'
                break
            fi
            printf '\n❌ Could not create the default directory.\n'
            printf 'Check storage permissions.\n'
            ;;

        3)
            printf '\nCustom directory path: '
            IFS= read -r CUSTOM_ROOT || exit 0

            if [[ -z "$CUSTOM_ROOT" ]]; then
                printf '\n⚠️ No path entered.\n'
                continue
            fi

            if [[ -d "$CUSTOM_ROOT" ]]; then
                BACKUP_ROOT="$CUSTOM_ROOT"
                printf '\n✅ Existing directory selected.\n'
                break
            fi

            printf '\n📁 Directory does not exist:\n%s\n' "$CUSTOM_ROOT"
            printf 'Create it? [y/N]: '
            IFS= read -r create_choice || exit 0

            case "$create_choice" in
                y|Y|yes|YES|Yes)
                    if mkdir -p -- "$CUSTOM_ROOT" && [[ -d "$CUSTOM_ROOT" ]]; then
                        BACKUP_ROOT="$CUSTOM_ROOT"
                        printf '\n✅ Custom directory created.\n'
                        break
                    fi
                    printf '\n❌ Could not create that directory.\n'
                    ;;
                *)
                    printf '\n↩️ Custom directory creation cancelled.\n'
                    ;;
            esac
            ;;

        0|q|Q)
            printf '\n👋 Recovery cancelled.\n'
            exit 0
            ;;

        *)
            printf '\n⚠️ Invalid selection. Choose 0, 1, 2 or 3.\n'
            ;;
    esac
done

printf '\n✅ Backup directory selected:\n%s\n' "$BACKUP_ROOT"

run_engine() {
    ZSHBACKUP_ROOT="$BACKUP_ROOT" perl - "$@" <<'__ZSHBACKUP_PERL__'
#!/data/data/com.termux/files/usr/bin/perl

use strict;
use warnings;
use File::Copy qw(copy);
use File::Path qw(make_path);
use Digest::SHA qw(sha256_hex);
use POSIX qw(strftime);

my $HOME = $ENV{HOME} // die "HOME is not set\n";
my $OUT  = $ENV{TERMUX_OUT} || "/sdcard/Download/termux-outputs";
my $ROOT = $ENV{ZSHBACKUP_ROOT} || "$OUT/ZSH_BACKUP";
my $BIN  = "$HOME/.local/bin";

my @CONFIG = qw(
    .zshrc
    .p10k.zsh
    .kaku_ff.jsonc
    .ku5i_ff.py
);

sub usage {
    print <<'HELP';

🛡️  ZSHBACKUP • PERL SNAPSHOT MANAGER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  zshbackup                 Create snapshot
  zshbackup list            List snapshots
  zshbackup latest          Show latest snapshot
  zshbackup verify          Verify latest snapshot
  zshbackup verify DATE     Verify chosen snapshot
  zshbackup restore DATE    Restore chosen snapshot
  zshbackup help            Show this help
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Snapshot contents:
  Main Zsh configuration
  Custom scripts from ~/.local/bin
  Manifest + SHA-256 checksums
HELP
}

sub snapshot_files {
    my @files;

    for my $name (@CONFIG) {
        my $path = "$HOME/$name";
        if (-f $path && !-l $path) {
            push @files, [$name, $path];
        } else {
            warn "⚠️ Skipping missing config: $name\n";
        }
    }

    if (opendir my $dh, $BIN) {
        for my $name (sort readdir $dh) {
            next if $name =~ /^\./;
            next if $name =~ /(?:\.bak(?:\.|$)|\.before_|\.pre-|~$)/i;

            my $path = "$BIN/$name";
            next unless -f $path && !-l $path;

            push @files, ["bin/$name", $path];
        }
        closedir $dh;
    } else {
        die "Cannot inspect $BIN: $!\n";
    }

    return @files;
}

sub safe_relative {
    my ($rel) = @_;
    return 0 unless defined $rel;
    return 1 if grep { $_ eq $rel } @CONFIG;
    return 1 if $rel =~ m{\Abin/[^/]+\z};
    return 0;
}

sub target_path {
    my ($rel) = @_;
    die "Unsafe snapshot path: $rel\n" unless safe_relative($rel);

    return "$HOME/$rel" unless $rel =~ m{\Abin/};
    (my $name = $rel) =~ s{\Abin/}{};
    return "$BIN/$name";
}

sub copy_preserving {
    my ($src, $dst) = @_;

    my @st = stat($src);
    die "Cannot stat $src: $!\n" unless @st;

    my $parent = $dst;
    $parent =~ s{/[^/]+$}{};
    make_path($parent) unless -d $parent;

    copy($src, $dst) or die "Copy failed: $src -> $dst: $!\n";
    chmod($st[2] & 07777, $dst) or die "chmod failed: $dst: $!\n";
    utime($st[8], $st[9], $dst);

    return $st[2] & 07777;
}

sub new_snapshot {
    make_path($ROOT) unless -d $ROOT;
    my $probe = "$ROOT/.ku5i_write_test.$$";
    open my $test, '>', $probe
        or die "Backup directory is not writable: $ROOT ($!)\n";
    close $test or die "Could not close write test: $!\n";
    unlink $probe or die "Could not remove write test: $!\n";

    my $stamp = strftime("%Y-%m-%d_%H-%M-%S", localtime);
    my $dir = "$ROOT/$stamp";
    my $suffix = 1;

    while (-e $dir) {
        $dir = sprintf("%s/%s-%02d", $ROOT, $stamp, $suffix++);
    }

    mkdir $dir or die "Cannot create snapshot $dir: $!\n";

    my @files = snapshot_files();
    my (@manifest, @checksums);

    eval {
        for my $entry (@files) {
            my ($rel, $src) = @$entry;
            my $dst = "$dir/$rel";
            my $mode = copy_preserving($src, $dst);
            my $size = -s $dst;
            my $hash = sha256_hex_file($dst);

            push @manifest, sprintf(
                "%-28s %8d bytes  mode=%04o",
                $rel, $size, $mode & 07777
            );

            push @checksums, "$hash  $rel";
        }

        open my $mf, '>', "$dir/manifest.txt"
            or die "Cannot write manifest: $!";
        print {$mf} "KU5I ZSH CONFIGURATION SNAPSHOT\n";
        print {$mf} "Created: $stamp\n";
        print {$mf} "Files: " . scalar(@files) . "\n\n";
        print {$mf} "$_\n" for @manifest;
        close $mf or die "Manifest close failed: $!";

        open my $cf, '>', "$dir/checksums.sha256"
            or die "Cannot write checksums: $!";
        print {$cf} "$_\n" for @checksums;
        close $cf or die "Checksum close failed: $!";
    };

    if ($@) {
        my $error = $@;
        remove_partial($dir);
        die $error;
    }

    print "\n🛡️ ZSH SNAPSHOT CREATED\n";
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    print "📁 $dir\n";
    print "📦 Files: " . scalar(@files) . "\n";
    printf "💾 Size: %.1f KiB\n", directory_size($dir) / 1024;
    print "🔐 SHA-256 checksums generated\n";
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";

    return $dir;
}

sub sha256_hex_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot hash $path: $!";
    binmode $fh;
    my $sha = Digest::SHA->new(256);
    $sha->addfile($fh);
    close $fh;
    return $sha->hexdigest;
}

sub directory_size {
    my ($dir) = @_;
    my $total = 0;
    for my $rel (snapshot_relative_files($dir)) {
        $total += -s "$dir/$rel";
    }
    $total += -s "$dir/manifest.txt" if -f "$dir/manifest.txt";
    $total += -s "$dir/checksums.sha256" if -f "$dir/checksums.sha256";
    return $total;
}

sub snapshot_relative_files {
    my ($dir) = @_;
    open my $fh, '<', "$dir/checksums.sha256"
        or die "Cannot read checksums: $!";
    my @paths;

    while (my $line = <$fh>) {
        chomp $line;
        next unless $line =~ /^[a-f0-9]{64}  (.+)$/;
        push @paths, $1;
    }

    close $fh;
    return @paths;
}

sub remove_partial {
    my ($dir) = @_;
    # Leave an incomplete snapshot available for diagnosis.
    warn "⚠️ Incomplete snapshot retained for inspection: $dir\n";
}

sub snapshots {
    return () unless -d $ROOT;
    opendir my $dh, $ROOT or die "Cannot open $ROOT: $!";
    my @dirs = sort grep {
        /^\d{4}-\d\d-\d\d_\d\d-\d\d-\d\d(?:-\d+)?$/
        && -d "$ROOT/$_"
    } readdir $dh;
    closedir $dh;
    return @dirs;
}

sub selected_snapshot {
    my ($requested) = @_;
    my @all = snapshots();

    my $stamp = $requested;
    $stamp = $all[-1] if !defined($stamp) && @all;

    die "No snapshots found in $ROOT\n" unless defined $stamp;
    die "Invalid snapshot name: $stamp\n"
        unless $stamp =~ /^\d{4}-\d\d-\d\d_\d\d-\d\d-\d\d(?:-\d+)?$/;
    die "Snapshot not found: $stamp\n" unless -d "$ROOT/$stamp";

    return "$ROOT/$stamp";
}

sub verify_snapshot {
    my ($dir) = @_;
    my $file = "$dir/checksums.sha256";

    open my $fh, '<', $file
        or die "Missing checksums file in $dir\n";

    my ($good, $bad) = (0, 0);

    while (my $line = <$fh>) {
        chomp $line;
        next unless $line =~ /^([a-f0-9]{64})  (.+)$/;

        my ($expected, $rel) = ($1, $2);

        if (!safe_relative($rel) || !-f "$dir/$rel") {
            print "❌ MISSING/INVALID: $rel\n";
            $bad++;
            next;
        }

        my $actual = sha256_hex_file("$dir/$rel");

        if ($actual eq $expected) {
            $good++;
        } else {
            print "❌ CHECKSUM MISMATCH: $rel\n";
            $bad++;
        }
    }

    close $fh;

    print "\n🔐 SNAPSHOT VERIFICATION\n";
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    print "Valid files: $good\n";
    print "Failed files: $bad\n";
    print $bad ? "⚠️ Verification FAILED\n" : "✅ All checksums match\n";
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";

    return $bad == 0;
}

sub list_snapshots {
    my @all = snapshots();

    print "\n📦 ZSH BACKUP SNAPSHOTS\n";
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";

    if (!@all) {
        print "No snapshots yet.\n";
        return;
    }

    for my $stamp (reverse @all) {
        my $dir = "$ROOT/$stamp";
        my $size = -s "$dir/manifest.txt" ? directory_size($dir) : 0;
        printf "📁 %-22s %8.1f KiB\n", $stamp, $size / 1024;
    }

    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    print "Total snapshots: " . scalar(@all) . "\n";
}

sub restore_snapshot {
    my ($dir) = @_;

    die "Snapshot verification failed; restore cancelled.\n"
        unless verify_snapshot($dir);

    my ($stamp) = $dir =~ m{/([^/]+)$};

    print "\n⚠️ RESTORE CONFIRMATION\n";
    print "Snapshot: $stamp\n";
    print "Existing matching config/scripts will be replaced.\n";
    print "Other custom scripts will NOT be deleted.\n";
    print "Type RESTORE to continue: ";

    my $answer = <STDIN> // '';
    chomp $answer;
    die "Restore cancelled.\n" unless $answer eq 'RESTORE';

    print "\nCreating pre-restore safety snapshot...\n";
    my $safety = new_snapshot();

    my @files = snapshot_relative_files($dir);

    for my $rel (@files) {
        my $src = "$dir/$rel";
        my $dst = target_path($rel);
        copy_preserving($src, $dst);
        chmod(($rel =~ m{\Abin/} ? 0700 : 0600), $dst);
        print "  ↳ Restored $rel\n";
    }

    print "\n✅ RESTORE COMPLETE\n";
    print "Safety snapshot: $safety\n";
    print "Restored files: " . scalar(@files) . "\n";
    print "Run: source ~/.zshrc\n";
}

my $action = shift(@ARGV) // 'create';

if ($action eq 'help' || $action eq '--help' || $action eq '-h') {
    usage();
}
elsif ($action eq 'create') {
    new_snapshot();
}
elsif ($action eq 'list') {
    list_snapshots();
}
elsif ($action eq 'latest') {
    my $dir = selected_snapshot();
    print "📁 Latest snapshot: $dir\n";
}
elsif ($action eq 'verify') {
    my $dir = selected_snapshot(shift @ARGV);
    exit(verify_snapshot($dir) ? 0 : 1);
}
elsif ($action eq 'restore') {
    my $dir = selected_snapshot(shift @ARGV);
    restore_snapshot($dir);
}
else {
    usage();
    die "Unknown command: $action\n";
}

__ZSHBACKUP_PERL__
}

while true; do
    printf '\n'
    printf '🛡️ ZSHBACKUP • RECOVERY MENU\n'
    printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    printf '  1. 📂 List snapshots\n'
    printf '  2. ♻️  Restore snapshot\n'
    printf '  0. 🚪 Exit\n'
    printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    printf '💡 Enter the number of your choice.\n'
    printf '💡 Restore will verify checksums and ask for confirmation.\n'
    printf '\nYour choice: '

    IFS= read -r choice || exit 0

    case "$choice" in
        1)
            run_engine list
            ;;
        2)
            printf '\n📂 AVAILABLE SNAPSHOTS\n'
            run_engine list
            printf '\n💡 Enter the exact snapshot folder name.\n'
            printf '💡 Press ENTER to restore the latest snapshot.\n'
            printf '💡 Type Q to cancel.\n'
            printf '\nSnapshot name: '
            IFS= read -r stamp || exit 0

            if [[ "$stamp" =~ ^[Qq]$ ]]; then
                printf '\n↩️ Restore cancelled.\n'
            elif [[ -n "$stamp" ]]; then
                run_engine restore "$stamp"
            else
                run_engine restore
            fi
            ;;
        0|q|Q)
            printf '\n👋 Recovery menu closed.\n'
            exit 0
            ;;
        *)
            printf '\n⚠️ Invalid selection. Choose 1, 2, or 0.\n'
            ;;
    esac

    printf '\nPress ENTER to return to menu...'
    IFS= read -r pause || exit 0
done
