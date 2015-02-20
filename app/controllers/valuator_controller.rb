require 'net/http'
require 'json'

class ValuatorController < ApplicationController
    def index
        @currencies=getTicker.keys
        if params[:form] then
            @addresses=params[:form][:addresses]
            @currency=params[:form][:currency]
            @coins={}
            @addresses.each_line {|adr|
                adr.chomp!
                if adr!="" then
                    coin={}
                    coin.merge!(getBTC(adr))
                    coin.merge!(getParty(adr))
                    @coins.store(adr,coin)
                end
            }
            @btcSum=0
            @currencySum=0
            @coins.each{|k1,v1|
                v1.each{|k,v|
                    value=0
                    if k=="BTC" then
                        v[:btc]=v[:amount]
                    else
                        v[:btc]=convert2BTC(k)*v[:amount]
                    end
                    rate=getTicker[@currency]["last"]
                    v[:value]=v[:btc]*rate
                    @btcSum=@btcSum+v[:btc]
                    @currencySum=@currencySum+v[:value]
                }
            }
        end
    end

    def getBTC(adr)
        uri=URI.parse('https://blockchain.info/q/addressbalance/'+adr)
        btc=Net::HTTP.get(uri).to_i
        if btc>0 then
            return {"BTC"=>{:amount=>btc*0.00000001}}
        end
        return {}
    end

    def getParty(adr)
        uri=URI.parse('http://xcp.blockscan.com/api2?module=address&action=balance&btc_address='+adr)
        json=JSON.parse(Net::HTTP.get(uri))
        if json["status"] != "success"
            return {}
        end

        coins={}
        json["data"].each{|asset|
            coins.store(asset["asset"],{:amount=>asset["balance"].to_i})
        }
        return coins
    end

    def convert2BTC(coin)
        uri=URI.parse('https://poloniex.com/public?command=returnTicker')
        json=JSON.parse(Net::HTTP.get(uri))
        ticker="BTC_"+coin
        if json[ticker]
            return json[ticker]["last"].to_f
        end
        return 0
    end

    def getTicker()
        uri=URI.parse('https://blockchain.info/ticker')
        json=JSON.parse(Net::HTTP.get(uri))
        return json
    end

end
