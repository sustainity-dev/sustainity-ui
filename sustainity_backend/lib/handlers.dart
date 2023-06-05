import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;

import 'package:sustainity_api/sustainity_api.dart' as api;

import 'db_client.dart' as db_client;
import 'retrievers.dart' as retrievers;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type',
};

class HealthCheckHandler {
  HealthCheckHandler();

  Future<shelf.Response> call(shelf.Request req) async {
    return shelf.Response.ok(null, headers: corsHeaders);
  }
}

class InfoHandler {
  db_client.DbClient client;
  JsonEncoder encoder;

  InfoHandler(this.client, this.encoder);

  Future<shelf.Response> call(shelf.Request req, String id) async {
    final dbInfo = await client.getInfo(id);
    if (dbInfo != null) {
      final apiInfo = dbInfo.toApi();
      return shelf.Response.ok(encoder.convert(apiInfo), headers: corsHeaders);
    } else {
      return shelf.Response.notFound(null, headers: corsHeaders);
    }
  }
}

class OrganisationSearchHandler {
  db_client.DbClient client;
  JsonEncoder encoder;

  OrganisationSearchHandler(this.client, this.encoder);

  Future<shelf.Response> call(shelf.Request req) async {
    final request = api.OrganisationTextSearchRequest.fromJson(
        req.requestedUri.queryParameters);
    final dbOrganisations = await client.searchOrganisations(request.query);
    final apiOrganisations = dbOrganisations.map((p) => p.toApi()).toList();
    final response =
        api.OrganisationTextSearchResponse(organisations: apiOrganisations);
    return shelf.Response.ok(encoder.convert(response), headers: corsHeaders);
  }
}

class ProductSearchHandler {
  db_client.DbClient client;
  JsonEncoder encoder;

  ProductSearchHandler(this.client, this.encoder);

  Future<shelf.Response> call(shelf.Request req) async {
    final request =
        api.ProductTextSearchRequest.fromJson(req.requestedUri.queryParameters);
    final dbProducts = await client.searchProducts(request.query);
    final apiProducts = dbProducts.map((p) => p.toApiFull()).toList();
    final response = api.ProductTextSearchResponse(products: apiProducts);
    return shelf.Response.ok(encoder.convert(response), headers: corsHeaders);
  }
}

class OrganisationHandler {
  db_client.DbClient client;
  JsonEncoder encoder;

  OrganisationHandler(this.client, this.encoder);

  Future<shelf.Response> call(shelf.Request req, String id) async {
    final dbOrganisation = await client.getOrganisation(id);
    if (dbOrganisation != null) {
      final apiOrganisation = dbOrganisation.toApi();
      return shelf.Response.ok(encoder.convert(apiOrganisation),
          headers: corsHeaders);
    } else {
      return shelf.Response.notFound(null, headers: corsHeaders);
    }
  }
}

class ProductHandler {
  db_client.DbClient client;
  JsonEncoder encoder;

  ProductHandler(this.client, this.encoder);

  Future<shelf.Response> call(shelf.Request req, String id) async {
    final dbProduct = await client.getProduct(id);
    if (dbProduct != null) {
      List<api.Organisation>? apiManufacturers;
      if (dbProduct.manufacturerIds != null) {
        apiManufacturers = [];
        for (final manufacturerId in dbProduct.manufacturerIds!) {
          final dbManufacturer = await client.getOrganisation(manufacturerId);
          if (dbManufacturer != null) {
            apiManufacturers.add(dbManufacturer.toApi());
          }
        }
      }

      final List<api.ProductShort> alternatives =
          await retrievers.retrieveAlternatives(client, dbProduct);
      final apiProduct = dbProduct.toApiFull(
          manufacturers: apiManufacturers, alternatives: alternatives);

      return shelf.Response.ok(encoder.convert(apiProduct),
          headers: corsHeaders);
    } else {
      return shelf.Response.notFound(null, headers: corsHeaders);
    }
  }
}

class AlternativesHandler {
  db_client.DbClient client;
  JsonEncoder encoder;

  AlternativesHandler(this.client, this.encoder);

  Future<shelf.Response> call(shelf.Request req, String id) async {
    final dbProduct = await client.getProduct(id);
    if (dbProduct != null) {
      final List<api.ProductShort> products =
          await retrievers.retrieveAlternatives(client, dbProduct);
      return shelf.Response.ok(encoder.convert(products), headers: corsHeaders);
    } else {
      return shelf.Response.notFound(null, headers: corsHeaders);
    }
  }
}