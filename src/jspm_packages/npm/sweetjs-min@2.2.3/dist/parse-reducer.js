"use strict";Object.defineProperty(exports,"__esModule",{value:!0});var _terms=require("./terms"),_terms2=_interopRequireDefault(_terms),_shiftReducer=require("shift-reducer");function _interopRequireDefault(a){return a&&a.__esModule?a:{default:a}}class ParseReducer extends _shiftReducer.CloneReducer{constructor(a){super(),this.context=a}reduceModule(a,b){return new _terms2.default("Module",{directives:b.directives.toArray(),items:b.items.toArray()})}reduceImport(a,b){let c=b.moduleSpecifier?b.moduleSpecifier.val():null;return new _terms2.default("Import",{defaultBinding:b.defaultBinding,namedImports:b.namedImports.toArray(),moduleSpecifier:c,forSyntax:a.forSyntax})}reduceImportNamespace(a,b){let c=b.moduleSpecifier?b.moduleSpecifier.val():null;return new _terms2.default("ImportNamespace",{defaultBinding:b.defaultBinding,namespaceBinding:b.namespaceBinding,moduleSpecifier:c,forSyntax:a.forSyntax})}reduceExport(a,b){return new _terms2.default("Export",{declaration:b.declaration})}reduceExportAllFrom(a,b){let c=b.moduleSpecifier?b.moduleSpecifier.val():null;return new _terms2.default("ExportAllFrom",{moduleSpecifier:c})}reduceExportFrom(a,b){let c=b.moduleSpecifier?b.moduleSpecifier.val():null;return new _terms2.default("ExportFrom",{moduleSpecifier:c,namedExports:b.namedExports.toArray()})}reduceExportSpecifier(a,b){let c=b.name,d=b.exportedName;return null==c?(c=d.resolve(this.context.phase),d=d.val()):(c=c.resolve(this.context.phase),d=d.val()),new _terms2.default("ExportSpecifier",{name:c,exportedName:d})}reduceImportSpecifier(a,b){let c=b.name?b.name.resolve(this.context.phase):null;return new _terms2.default("ImportSpecifier",{name:c,binding:b.binding})}reduceIdentifierExpression(a){return new _terms2.default("IdentifierExpression",{name:a.name.resolve(this.context.phase)})}reduceLiteralNumericExpression(a){return new _terms2.default("LiteralNumericExpression",{value:a.value.val()})}reduceLiteralBooleanExpression(a){return new _terms2.default("LiteralBooleanExpression",{value:"true"===a.value.val()})}reduceLiteralStringExpression(a){return new _terms2.default("LiteralStringExpression",{value:a.value.token.str})}reduceCallExpression(a,b){return new _terms2.default("CallExpression",{callee:b.callee,arguments:b.arguments.toArray()})}reduceFunctionBody(a,b){return new _terms2.default("FunctionBody",{directives:b.directives.toArray(),statements:b.statements.toArray()})}reduceFormalParameters(a,b){return new _terms2.default("FormalParameters",{items:b.items.toArray(),rest:b.rest})}reduceBindingIdentifier(a){return new _terms2.default("BindingIdentifier",{name:a.name.resolve(this.context.phase)})}reduceBinaryExpression(a,b){return new _terms2.default("BinaryExpression",{left:b.left,operator:a.operator.val(),right:b.right})}reduceObjectExpression(a,b){return new _terms2.default("ObjectExpression",{properties:b.properties.toArray()})}reduceVariableDeclaration(a,b){return new _terms2.default("VariableDeclaration",{kind:b.kind,declarators:b.declarators.toArray()})}reduceStaticPropertyName(a){return new _terms2.default("StaticPropertyName",{value:a.value.val().toString()})}reduceArrayExpression(a,b){return new _terms2.default("ArrayExpression",{elements:b.elements.toArray()})}reduceStaticMemberExpression(a,b){return new _terms2.default("StaticMemberExpression",{object:b.object,property:b.property.val()})}}exports.default=ParseReducer;
