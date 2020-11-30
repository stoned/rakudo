# A name. Names range from simple (a single identifier) up to rather more
# complex (including pseudo-packages, interpolated parts, etc.)
class RakuAST::Name is RakuAST::Node {
    has List $!parts;

    method new(*@parts) {
        my $obj := nqp::create(self);
        nqp::bindattr($obj, RakuAST::Name, '$!parts', @parts);
        $obj
    }

    method from-identifier(Str $identifier) {
        self.new(RakuAST::Name::Part::Simple.new($identifier))
    }

    method parts() {
        self.IMPL-WRAP-LIST($!parts)
    }

    method is-identifier() {
        nqp::elems($!parts) == 1 && nqp::istype($!parts[0], RakuAST::Name::Part::Simple)
    }

    method canonicalize() {
        nqp::die('canonicalize NYI for non-identifier names') unless self.is-identifier;
        $!parts[0].name
    }

    method IMPL-QAST-PACKAGE-LOOKUP(RakuAST::IMPL::QASTContext $context, Mu $start-package) {
        my $result := $start-package;
        my $final := $!parts[nqp::elems($!parts) - 1];
        for $!parts {
            # We do .WHO on the current package, followed by the index into it.
            $result := QAST::Op.new( :op('who'), $result );
            $result := $_.IMPL-QAST-PACKAGE-LOOKUP-PART($context, $result, $_ =:= $final);
        }
        $result
    }
}

# Marker role for a part of a name.
class RakuAST::Name::Part {
}

# A simple name part, wrapping a string name.
class RakuAST::Name::Part::Simple is RakuAST::Name::Part {
    has str $.name;

    method new(Str $name) {
        my $obj := nqp::create(self);
        nqp::bindattr_s($obj, RakuAST::Name::Part::Simple, '$!name', $name);
        $obj
    }

    method IMPL-QAST-PACKAGE-LOOKUP-PART(RakuAST::IMPL::QASTContext $context, Mu $stash-qast, Int $is-final) {
        QAST::Op.new(
            :op('callmethod'),
            :name($is-final ?? 'AT-KEY' !! 'package_at_key'),
            $stash-qast,
            QAST::SVal.new( :value($!name) )
        )
    }
}
