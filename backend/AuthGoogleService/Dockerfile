FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY AuthGoogleService.csproj ./
RUN dotnet restore AuthGoogleService.csproj

COPY . ./
RUN dotnet publish AuthGoogleService.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish ./

ENV ASPNETCORE_ENVIRONMENT=Production
EXPOSE 10000

CMD ["sh", "-c", "dotnet AuthGoogleService.dll --urls http://0.0.0.0:${PORT:-10000}"]
