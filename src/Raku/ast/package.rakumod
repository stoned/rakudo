class RakuAST::Package is RakuAST::StubbyMeta is RakuAST::Term is RakuAST::LexicalScope
                       is RakuAST::Declaration is RakuAST::AttachTarget {
    has Str $.package-declarator;
    has Mu $.how;
    has Str $.name;
    has Str $.repr;
    has RakuAST::Blockoid $.body;

    # Methods and attributes are not directly added, but rather thorugh the
    # RakuAST::Attaching mechanism.
    has Mu $!attached-methods;
    has Mu $!attached-attributes;

    method new(Str :$package-declarator!, Mu :$how!, Str :$name, Str :$repr, RakuAST::Blockoid :$body) {
        my $obj := nqp::create(self);
        nqp::bindattr($obj, RakuAST::Package, '$!package-declarator', $package-declarator);
        nqp::bindattr($obj, RakuAST::Package, '$!how', $how);
        nqp::bindattr($obj, RakuAST::Package, '$!name', $name // Str);
        nqp::bindattr($obj, RakuAST::Package, '$!repr', $repr // Str);
        nqp::bindattr($obj, RakuAST::Package, '$!body', $body // RakuAST::Blockoid.new);
        nqp::bindattr($obj, RakuAST::Package, '$!attached-methods', []);
        nqp::bindattr($obj, RakuAST::Package, '$!attached-attributes', []);
        $obj
    }

    method default-scope() { 'our' }

    method attach-target-names() { self.IMPL-WRAP-LIST(['package', 'also']) }

    method clear-attachments() {
        nqp::setelems($!attached-methods, 0);
        nqp::setelems($!attached-attributes, 0);
        Nil
    }

    method ATTACH-METHOD(RakuAST::Method $method) {
        nqp::push($!attached-methods, $method);
        Nil
    }

    # TODO also list-y declarations
    method ATTACH-ATTRIBUTE(RakuAST::VarDeclaration::Simple $attribute) {
        nqp::push($!attached-attributes, $attribute);
        Nil
    }

    method PRODUCE-STUBBED-META-OBJECT() {
        # Create the type object and return it; this stubs the type.
        my %options;
        %options<name> := $!name if $!name;
        %options<repr> := $!repr if $!repr;
        $!how.new_type(|%options)
    }

    method PRODUCE-META-OBJECT() {
        # Obtain the stubbed meta-object, which is the type object.
        my $type := self.stubbed-meta-object();

        # Add methods and attributes.
        for $!attached-methods {
            $type.HOW.add_method($type, $_.name, $_.meta-object);
        }
        for $!attached-attributes {
            $type.HOW.add_attribute($type, $_.meta-object);
        }

        # Compose the meta-object and return it.
        $type.HOW.compose($type);
        $type
    }

    method IMPL-TO-QAST(RakuAST::IMPL::QASTContext $context) {
        my $type-object := self.meta-object;
        $context.ensure-sc($type-object);
        QAST::WVal.new( :value($type-object) )
    }

    method visit-children(Code $visitor) {
        $visitor($!body);
    }
}
